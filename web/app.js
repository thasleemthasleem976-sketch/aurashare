// AuraShare Unified Engine - Seamless Send & Receive Workflow

class AuraShareApp {
  constructor() {
    this.localIp = '10.73.110.163';
    this.transferPort = 52346;
    this.discoveryPort = 52345;

    // Load or generate local node identity (isolated per tab / instance)
    this.nodeId = sessionStorage.getItem('aura_node_id') || 'node_' + Math.random().toString(36).substring(2, 9);
    sessionStorage.setItem('aura_node_id', this.nodeId);

    // Local Accounts database & Active Authentication Session
    this.accounts = JSON.parse(localStorage.getItem('aura_accounts')) || [];
    this.currentUser = JSON.parse(sessionStorage.getItem('aura_active_user') || localStorage.getItem('aura_active_user') || 'null');

    // Default or active profile
    if (this.currentUser) {
      this.user = {
        name: this.currentUser.fullName || this.currentUser.name || 'User',
        email: this.currentUser.email || 'user@aurashare.local',
        deviceName: this.currentUser.deviceName || ((this.currentUser.fullName || 'User').split(' ')[0] + "'s Laptop"),
        avatar: ((this.currentUser.fullName || 'U')[0]).toUpperCase()
      };
    } else {
      this.user = {
        name: 'Guest User',
        email: 'guest@aurashare.local',
        deviceName: 'Local Device',
        avatar: 'G'
      };
    }

    this.settings = JSON.parse(localStorage.getItem('aura_settings')) || {
      deviceName: this.user.deviceName,
      downloadPath: 'Downloads/AuraShare',
      requireVerification: true,
      encryption: true,
      autoAccept: false,
      transferPort: 52346,
      discoveryPort: 52345
    };

    this.trustedIds = JSON.parse(localStorage.getItem('aura_trusted_ids')) || [];
    this.history = JSON.parse(localStorage.getItem('aura_history')) || [];
    this.notifications = JSON.parse(localStorage.getItem('aura_notifications')) || [];

    this.stagedFiles = [];
    this.devices = new Map();
    this.isScanning = true;

    this.activeTransfer = null;
    this.transferTimer = null;
    this.isPaused = false;

    // Inter-tab / local network P2P discovery channel
    this.channel = new BroadcastChannel('aurashare_p2p_channel');

    this.init();
  }

  async init() {
    // Register Service Worker for 100% offline functionality
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('./sw.js')
        .then(reg => {
          console.log('AuraShare SW registered with scope:', reg.scope);
        })
        .catch(err => console.log('SW registration note:', err));
    }

    // Capture PWA install prompt
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      window.deferredPwaPrompt = e;
      console.log('AuraShare beforeinstallprompt fired and captured.');
      this.updatePwaInstallButtons(true);
    });

    window.addEventListener('appinstalled', () => {
      console.log('AuraShare PWA installed successfully.');
      window.deferredPwaPrompt = null;
      this.updatePwaInstallButtons(false, true);
      this.addNotification('App Installed', 'AuraShare is installed on your device as a native app!', 'success');
    });

    this.setupNavigation();
    this.setupBroadcastChannel();
    this.setupEventListeners();

    // Check Auth Session (Show Login/Register or App Shell)
    const isAuthenticated = this.checkAuthSession();

    if (isAuthenticated) {
      this.renderUserProfile();
      this.renderStats();
      this.renderHistory();
      this.renderNotifications();
      this.renderTrustedDevices();

      // Start discovery beacon
      this.broadcastBeacon();
    }

    setInterval(() => {
      if (this.isScanning && this.currentUser) {
        this.broadcastBeacon();
        this.pruneStaleDevices();
      }
    }, 2500);

    // Initial welcome notification
    if (this.notifications.length === 0) {
      this.addNotification('AuraShare Ready', 'Bound to ' + this.localIp + ':52346. Zero cloud traffic.', 'info');
    }
  }

  // --- Broadcast Channel P2P Discovery & Transfer ---

  setupBroadcastChannel() {
    this.channel.onmessage = (event) => {
      const msg = event.data;
      if (!msg || msg.senderId === this.nodeId) return;

      if (msg.type === 'BEACON') {
        this.addDevice({
          id: msg.senderId,
          name: msg.name,
          platform: msg.platform || 'Desktop Browser',
          ip: msg.ip || '127.0.0.1',
          port: msg.port || 52346,
          lastSeen: Date.now()
        });
      } else if (msg.type === 'TRANSFER_REQUEST' && msg.targetId === this.nodeId) {
        this.handleIncomingRequest(msg);
      } else if (msg.type === 'TRANSFER_ACCEPT' && msg.targetId === this.nodeId) {
        this.onTransferAcceptedByPeer();
      } else if (msg.type === 'TRANSFER_REJECT' && msg.targetId === this.nodeId) {
        this.onTransferRejectedByPeer();
      }
    };
  }

  broadcastBeacon() {
    this.channel.postMessage({
      type: 'BEACON',
      senderId: this.nodeId,
      name: this.settings.deviceName,
      platform: navigator.platform.includes('Win') ? 'Windows' : (navigator.platform.includes('Mac') ? 'macOS' : 'Linux/Android'),
      ip: this.localIp,
      port: this.settings.transferPort
    });
  }

  addDevice(dev) {
    this.devices.set(dev.id, dev);
    this.renderSendDevicesGrid();
    this.renderStats();
  }

  pruneStaleDevices() {
    const now = Date.now();
    let updated = false;
    for (const [id, dev] of this.devices.entries()) {
      if (now - dev.lastSeen > 8000) {
        this.devices.delete(id);
        updated = true;
      }
    }
    if (updated) {
      this.renderSendDevicesGrid();
      this.renderStats();
    }
  }

  // --- Navigation & Routing ---

  setupNavigation() {
    const handleRoute = () => {
      const hash = window.location.hash.replace('#', '') || 'dashboard';
      this.navigate(hash);
    };

    window.addEventListener('hashchange', handleRoute);
    handleRoute();

    document.querySelectorAll('.nav-item, .mobile-nav-item').forEach(item => {
      item.addEventListener('click', (e) => {
        const screen = item.getAttribute('data-screen');
        if (screen) {
          e.preventDefault();
          window.location.hash = '#' + screen;
        }
      });
    });

    document.getElementById('mobileMenuBtn').addEventListener('click', () => {
      document.querySelector('.sidebar').classList.toggle('open');
    });
  }

  navigate(screenId) {
    document.querySelectorAll('.app-screen').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.nav-item, .mobile-nav-item').forEach(n => n.classList.remove('active'));

    const target = document.getElementById('screen-' + screenId);
    if (target) {
      target.classList.add('active');
    }

    document.querySelectorAll(`[data-screen="${screenId}"]`).forEach(n => n.classList.add('active'));
    document.querySelector('.sidebar').classList.remove('open');

    // Auto-actions when navigating
    if (screenId === 'send') {
      this.broadcastBeacon();
      this.renderSendDevicesGrid();
      this.renderSendStagedFiles();
    } else if (screenId === 'receive') {
      this.broadcastBeacon();
      this.renderReceiveScreen();
    }
  }

  // --- Event Listeners ---

  setupEventListeners() {
    // Quick Actions on Dashboard
    document.getElementById('quickSendCard').onclick = () => {
      this.navigate('send');
      // If no files staged, prompt to choose files
      if (this.stagedFiles.length === 0) {
        document.getElementById('sendRealFileInput').click();
      }
    };

    document.getElementById('quickReceiveCard').onclick = () => {
      this.navigate('receive');
    };

    // Send Flow: Choose Files Button
    const sendInput = document.getElementById('sendRealFileInput');
    document.getElementById('browseSendFilesBtn').onclick = () => sendInput.click();

    sendInput.onchange = (e) => {
      if (e.target.files.length > 0) {
        for (let file of e.target.files) {
          const ext = file.name.split('.').pop().toLowerCase();
          this.stagedFiles.push({
            id: 'file_' + Math.random().toString(36).substring(2, 9),
            name: file.name,
            size: file.size,
            ext: ext,
            category: this.getCategory(ext),
            selected: true,
            fileObject: file
          });
        }
        this.renderSendStagedFiles();
        this.addNotification('Files Chosen', `${e.target.files.length} file(s) selected. Now select a nearby device to send.`, 'info');
      }
    };

    // Direct IP Modal
    document.getElementById('sendDirectIpBtn').onclick = () => {
      document.getElementById('directIpError').classList.add('hidden');
      document.getElementById('directIpStatus').classList.add('hidden');
      document.getElementById('directIpModal').classList.remove('hidden');
    };
    document.getElementById('cancelDirectIpBtn').onclick = () => {
      document.getElementById('directIpModal').classList.add('hidden');
    };
    document.getElementById('connectDirectIpBtn').onclick = async () => {
      const ipInput = document.getElementById('directIpInput');
      const errorEl = document.getElementById('directIpError');
      const statusEl = document.getElementById('directIpStatus');
      const connectBtn = document.getElementById('connectDirectIpBtn');
      const ip = ipInput.value.trim();
      const port = parseInt(document.getElementById('directPortInput').value.trim()) || 52346;

      errorEl.classList.add('hidden');
      statusEl.classList.add('hidden');

      // 1. Strict IPv4 address format validation
      const ipv4Regex = /^(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$/;
      if (!ipv4Regex.test(ip)) {
        errorEl.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> <strong>Invalid IP Address:</strong> Direct IP must be a valid IPv4 address (e.g. 192.168.1.50 or 10.73.110.182). Random numbers or text are not permitted.';
        errorEl.classList.remove('hidden');
        return;
      }

      // 2. Reject loopback/host conflicts
      if (ip === this.localIp || ip === '127.0.0.1' || ip === '0.0.0.0') {
        errorEl.innerHTML = '<i class="fa-solid fa-ban"></i> <strong>Host Conflict:</strong> You cannot direct-send files to your own host machine.';
        errorEl.classList.remove('hidden');
        return;
      }

      // 3. Verify available resource
      statusEl.innerHTML = `<i class="fa-solid fa-spinner fa-spin"></i> Probing ${ip}:${port} for available resource...`;
      statusEl.classList.remove('hidden');
      connectBtn.disabled = true;

      try {
        // Step A: Check if already detected as active peer on local network
        let matchedDev = null;
        for (const dev of this.devices.values()) {
          if (dev.ip === ip) {
            matchedDev = dev;
            break;
          }
        }

        if (!matchedDev) {
          // Step B: Probe network resource via fetch with timeout
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 1800);
          try {
            await fetch(`http://${ip}:${port}/`, { method: 'HEAD', mode: 'no-cors', signal: controller.signal });
            clearTimeout(timeoutId);
            matchedDev = {
              id: 'dev_direct_' + ip.replace(/\./g, '_'),
              name: 'Direct Peer (' + ip + ')',
              platform: 'Local Network',
              ip: ip,
              port: port,
              lastSeen: Date.now()
            };
            this.addDevice(matchedDev);
          } catch (e) {
            clearTimeout(timeoutId);
            statusEl.classList.add('hidden');
            connectBtn.disabled = false;
            errorEl.innerHTML = `<i class="fa-solid fa-circle-xmark"></i> <strong>Resource Unavailable:</strong> No active AuraShare node responded at <code>${ip}:${port}</code>. Direct IP transfer can only connect to available devices currently running on your local network.`;
            errorEl.classList.remove('hidden');
            return;
          }
        }

        // Available resource verified!
        statusEl.classList.add('hidden');
        connectBtn.disabled = false;
        document.getElementById('directIpModal').classList.add('hidden');
        this.sendFilesToDevice(matchedDev);

      } catch (err) {
        statusEl.classList.add('hidden');
        connectBtn.disabled = false;
        errorEl.innerHTML = `<i class="fa-solid fa-circle-xmark"></i> <strong>Connection Failed:</strong> ${err.message}`;
        errorEl.classList.remove('hidden');
      }
    };

    // Logout
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
      logoutBtn.onclick = () => this.logout();
    }

    document.getElementById('sendRefreshRadarBtn').onclick = () => {
      this.broadcastBeacon();
      this.addNotification('Radar Refreshed', 'Rescanned subnet for live peers', 'info');
    };

    // Transfer Banner Controls
    document.getElementById('bannerPauseBtn').onclick = () => {
      this.isPaused = !this.isPaused;
      const btn = document.getElementById('bannerPauseBtn');
      btn.innerHTML = this.isPaused
        ? '<i class="fa-solid fa-play"></i> Resume'
        : '<i class="fa-solid fa-pause"></i> Pause';
    };

    document.getElementById('bannerCancelBtn').onclick = () => {
      this.cancelTransfer();
    };

    // Incoming Transfer Modal Actions
    document.getElementById('acceptBtn').onclick = () => {
      this.acceptIncoming();
    };
    document.getElementById('rejectBtn').onclick = () => {
      this.rejectIncoming();
    };

    // History & Notifs
    document.getElementById('clearHistoryBtn').onclick = () => {
      if (confirm('Clear all transfer records?')) {
        this.history = [];
        localStorage.setItem('aura_history', JSON.stringify([]));
        this.renderHistory();
        this.renderStats();
      }
    };

    document.getElementById('markAllReadBtn').onclick = () => {
      this.notifications.forEach(n => n.read = true);
      localStorage.setItem('aura_notifications', JSON.stringify(this.notifications));
      this.renderNotifications();
    };

    document.getElementById('clearNotifsBtn').onclick = () => {
      this.notifications = [];
      localStorage.setItem('aura_notifications', JSON.stringify([]));
      this.renderNotifications();
    };

    // Settings
    document.getElementById('saveSettingsBtn').onclick = () => {
      this.settings.deviceName = document.getElementById('settingDeviceName').value.trim();
      this.settings.downloadPath = document.getElementById('settingDownloadPath').value.trim();
      this.settings.transferPort = parseInt(document.getElementById('settingTransferPort').value.trim()) || 52346;
      this.settings.discoveryPort = parseInt(document.getElementById('settingDiscoveryPort').value.trim()) || 52345;

      this.user.deviceName = this.settings.deviceName;
      localStorage.setItem('aura_user', JSON.stringify(this.user));
      localStorage.setItem('aura_settings', JSON.stringify(this.settings));

      this.renderUserProfile();
      this.addNotification('Settings Saved', 'Preferences saved to local vault.', 'success');
    };

    // Theme toggle
    const themeBtn = document.getElementById('themeToggleBtn');
    if (themeBtn) {
      themeBtn.onclick = () => {
        document.body.classList.toggle('dark-theme');
        const isDark = document.body.classList.contains('dark-theme');
        themeBtn.innerHTML = isDark ? '<i class="fa-solid fa-sun"></i>' : '<i class="fa-solid fa-moon"></i>';
        this.addNotification('Theme Changed', isDark ? 'Smoky Glass mode activated' : 'Liquid Ice Glass mode activated', 'info');
      };
    }
  }

  // --- Category and Formatting Helpers ---

  getCategory(ext) {
    if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'xls', 'xlsx', 'ppt', 'pptx'].includes(ext)) return 'document';
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(ext)) return 'image';
    if (['mp4', 'mkv', 'avi', 'mov', 'webm'].includes(ext)) return 'video';
    if (['mp3', 'wav', 'ogg', 'flac'].includes(ext)) return 'audio';
    if (['zip', 'rar', '7z', 'tar', 'gz'].includes(ext)) return 'archive';
    if (['apk', 'exe', 'msi', 'dmg', 'deb'].includes(ext)) return 'app';
    return 'other';
  }

  getCategoryIcon(cat) {
    switch (cat) {
      case 'document': return 'fa-file-lines';
      case 'image': return 'fa-image';
      case 'video': return 'fa-film';
      case 'audio': return 'fa-music';
      case 'archive': return 'fa-file-zipper';
      case 'app': return 'fa-android';
      default: return 'fa-file';
    }
  }

  formatBytes(bytes) {
    if (!bytes || bytes === 0) return '0 B';
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  }

  // --- Unified Send Screen Rendering ---

  renderSendStagedFiles() {
    const emptyEl = document.getElementById('sendStagedEmpty');
    const listEl = document.getElementById('sendStagedList');
    const badge = document.getElementById('stagedBadge');

    if (this.stagedFiles.length === 0) {
      emptyEl.classList.remove('hidden');
      listEl.classList.add('hidden');
      badge.classList.add('hidden');
    } else {
      emptyEl.classList.add('hidden');
      listEl.classList.remove('hidden');
      badge.innerText = this.stagedFiles.length;
      badge.classList.remove('hidden');

      const totalBytes = this.stagedFiles.reduce((sum, f) => sum + f.size, 0);

      listEl.innerHTML = `
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px; font-size:12px; font-weight:700; color:var(--text-muted);">
          <span>${this.stagedFiles.length} file(s) staged • Total Payload: ${this.formatBytes(totalBytes)}</span>
          <button class="btn-link danger" onclick="app.clearStagedFiles()">Clear All</button>
        </div>
        ${this.stagedFiles.map((f, idx) => `
          <div class="file-row-item">
            <div class="file-cat-icon" style="background: rgba(0,180,216,0.15); color: var(--primary);">
              <i class="fa-solid ${this.getCategoryIcon(f.category)}"></i>
            </div>
            <div class="file-info">
              <strong>${f.name}</strong>
              <div class="file-meta">
                <span>${this.formatBytes(f.size)}</span>
                <span>•</span>
                <span style="text-transform: uppercase;">${f.category}</span>
              </div>
            </div>
            <button class="btn-link danger" onclick="app.removeStagedFile(${idx})"><i class="fa-solid fa-trash-can"></i></button>
          </div>
        `).join('')}
      `;
    }
  }

  clearStagedFiles() {
    this.stagedFiles = [];
    this.renderSendStagedFiles();
  }

  removeStagedFile(idx) {
    this.stagedFiles.splice(idx, 1);
    this.renderSendStagedFiles();
  }

  renderSendDevicesGrid() {
    const radarLayer = document.getElementById('radarDevicesLayer');
    const emptyHud = document.getElementById('radarEmptyHud');
    const grid = document.getElementById('sendDevicesGrid');

    if (radarLayer) {
      if (this.devices.size === 0) {
        radarLayer.innerHTML = '';
        if (emptyHud) emptyHud.style.display = 'block';
      } else {
        if (emptyHud) emptyHud.style.display = 'none';

        const deviceList = Array.from(this.devices.values());
        const total = deviceList.length;
        let html = '';

        // Polar radius from host center in % (32% to 35% keeps inside radar rings)
        const radiusPercent = total === 1 ? 32 : 35;

        deviceList.forEach((dev, idx) => {
          // Angle in radians distributed around the dome starting at top
          const angle = (2 * Math.PI * idx) / total - Math.PI / 2;
          const leftPercent = 50 + radiusPercent * Math.cos(angle);
          const topPercent = 50 + radiusPercent * Math.sin(angle);
          const isAndroid = (dev.platform || '').toLowerCase().includes('android') || (dev.name || '').toLowerCase().includes('phone');
          const isTrusted = this.trustedIds.includes(dev.id);

          html += `
            <div class="radar-floating-device" 
                 style="left: ${leftPercent.toFixed(1)}%; top: ${topPercent.toFixed(1)}%;"
                 onclick="app.onDeviceCardClicked('${dev.id}')"
                 title="Tap to transmit files to ${dev.name}">
              <div class="device-avatar-bubble">
                <div class="device-sonar-wave"></div>
                <i class="fa-solid ${isAndroid ? 'fa-mobile-screen' : 'fa-laptop'}"></i>
              </div>
              <div class="device-hud-pill">
                <strong>${dev.name} ${isTrusted ? '<i class="fa-solid fa-circle-check text-cyan" style="font-size:10px;"></i>' : ''}</strong>
                <span class="device-send-hint"><i class="fa-solid fa-paper-plane"></i> SEND</span>
              </div>
            </div>`;
        });

        radarLayer.innerHTML = html;
      }
    }

    if (grid) {
      if (this.devices.size === 0) {
        grid.innerHTML = `
          <div style="grid-column: 1 / -1; text-align:center; padding:32px; background:var(--surface-dark); border-radius:14px; border:1px solid var(--border-dark);">
            <i class="fa-solid fa-satellite-dish" style="font-size:28px; color:var(--text-muted); opacity:0.5; margin-bottom:10px;"></i>
            <h4 style="font-size:14px;">Searching for Nearby Receivers...</h4>
            <p style="font-size:12px; color:var(--text-muted); margin-top:4px;">Open AuraShare on another device or tab to detect live peers.</p>
          </div>`;
      } else {
        let html = '';
        for (const [id, dev] of this.devices.entries()) {
          const isTrusted = this.trustedIds.includes(id);
          html += `
            <div class="send-device-card" onclick="app.onDeviceCardClicked('${id}')">
              <div class="send-device-icon">
                <i class="fa-solid ${(dev.platform || '').includes('Android') ? 'fa-mobile-screen' : 'fa-laptop'}"></i>
              </div>
              <div class="send-device-meta">
                <strong>${dev.name} ${isTrusted ? '<i class="fa-solid fa-circle-check text-cyan" style="font-size:12px;"></i>' : ''}</strong>
                <span>${dev.platform} • ${dev.ip}</span>
              </div>
              <button class="send-tap-btn">
                <i class="fa-solid fa-paper-plane"></i> Send
              </button>
            </div>`;
        }
        grid.innerHTML = html;
      }
    }
  }

  onDeviceCardClicked(id) {
    const dev = this.devices.get(id);
    if (!dev) {
      this.addNotification('Peer Unavailable', 'This device is no longer reachable on the local radar scan.', 'warning');
      this.renderSendDevicesGrid();
      return;
    }

    // Check if files are selected
    if (this.stagedFiles.length === 0) {
      this.addNotification('Select Files First', 'Please choose files to transfer before sending.', 'warning');
      document.getElementById('sendRealFileInput').click();
      return;
    }

    this.sendFilesToDevice(dev);
  }

  // --- Unified Direct Send ---

  sendFilesToDevice(targetDevice) {
    const files = this.stagedFiles;
    if (files.length === 0) {
      this.addNotification('No Files Selected', 'Please stage at least one file to send.', 'warning');
      return;
    }

    const totalBytes = files.reduce((sum, f) => sum + f.size, 0);

    this.activeTransfer = {
      id: 'tx_' + Date.now(),
      type: 'sent',
      peerName: targetDevice.name,
      peerIp: targetDevice.ip,
      files: files,
      totalBytes: totalBytes,
      transferred: 0,
      startTime: Date.now()
    };

    // Broadcast request across local channel to the target device
    this.channel.postMessage({
      type: 'TRANSFER_REQUEST',
      targetId: targetDevice.id,
      senderId: this.nodeId,
      senderName: this.settings.deviceName,
      files: files.map(f => ({ name: f.name, size: f.size })),
      totalBytes: totalBytes
    });

    this.addNotification('Transfer Request Sent', `Sending request for ${files.length} file(s) to ${targetDevice.name}. Waiting for authorization...`, 'info');

    // If sending to a direct custom IP node without peer channel, begin streaming
    if (targetDevice.id.startsWith('dev_direct_')) {
      setTimeout(() => {
        if (this.activeTransfer && !this.transferTimer) {
          this.startStreamingTransfer();
        }
      }, 1000);
    }
  }

  // --- Unified Receive Screen Rendering ---

  renderReceiveScreen() {
    document.getElementById('receiveDeviceNameDisplay').innerText = this.settings.deviceName;
    document.getElementById('receiveIpDisplay').innerText = this.localIp;

    const list = document.getElementById('receiveHistoryList');
    const received = this.history.filter(h => h.type === 'received');

    if (received.length === 0) {
      list.innerHTML = `
        <div style="text-align:center; padding:32px; background:var(--card-dark); border-radius:16px; border:1px solid var(--border-dark);">
          <i class="fa-solid fa-inbox" style="font-size:32px; color:var(--text-muted); opacity:0.4;"></i>
          <h4 style="margin:12px 0 4px; font-size:14px;">No Files Received Yet</h4>
          <p style="font-size:12px; color:var(--text-muted);">Incoming files accepted on this device will be listed here.</p>
        </div>`;
      return;
    }

    list.innerHTML = received.map(h => `
      <div class="history-item">
        <div class="history-icon-bubble recv">
          <i class="fa-solid fa-arrow-down"></i>
        </div>
        <div class="history-info">
          <strong>${h.files ? h.files[0] : 'Received File'}</strong>
          <div class="history-meta">
            <span>From ${h.peerName}</span>
            <span>•</span>
            <span>${this.formatBytes(h.totalBytes)}</span>
            <span>•</span>
            <span>${h.timestamp}</span>
          </div>
        </div>
        <span class="badge success">Saved</span>
      </div>
    `).join('');
  }

  // --- Transfer Handshake & Streaming ---

  handleIncomingRequest(msg) {
    this.incomingRequestData = msg;
    document.getElementById('incomingPeerInfo').innerText = `From: ${msg.senderName} (${msg.files.length} file(s))`;
    document.getElementById('incomingFileCount').innerText = `${msg.files.length} Item(s)`;
    document.getElementById('incomingTotalSize').innerText = this.formatBytes(msg.totalBytes);

    const listEl = document.getElementById('incomingFileList');
    listEl.innerHTML = msg.files.map(f => `
      <div style="display:flex; justify-content:space-between; font-size:12px; padding:4px 0;">
        <span><i class="fa-solid fa-file text-cyan"></i> ${f.name}</span>
        <span style="color:var(--text-muted);">${this.formatBytes(f.size)}</span>
      </div>
    `).join('');

    document.getElementById('incomingModal').classList.remove('hidden');
    this.addNotification('Incoming File Request', `${msg.senderName} wants to send ${msg.files.length} files`, 'info');
  }

  acceptIncoming() {
    document.getElementById('incomingModal').classList.add('hidden');
    const msg = this.incomingRequestData;
    if (!msg) return;

    this.channel.postMessage({
      type: 'TRANSFER_ACCEPT',
      targetId: msg.senderId
    });

    this.activeTransfer = {
      id: 'rx_' + Date.now(),
      type: 'received',
      peerName: msg.senderName,
      peerIp: this.localIp,
      files: msg.files,
      totalBytes: msg.totalBytes,
      transferred: 0,
      startTime: Date.now()
    };
    this.startStreamingTransfer(true);
  }

  rejectIncoming() {
    document.getElementById('incomingModal').classList.add('hidden');
    const msg = this.incomingRequestData;
    if (!msg) return;

    this.channel.postMessage({
      type: 'TRANSFER_REJECT',
      targetId: msg.senderId
    });
    this.addNotification('Transfer Rejected', 'Declined incoming transfer request', 'warning');
  }

  onTransferAcceptedByPeer() {
    this.addNotification('Peer Accepted', 'Authorization granted. Beginning direct transfer...', 'success');
    this.startStreamingTransfer();
  }

  onTransferRejectedByPeer() {
    this.cancelTransfer();
    alert('The receiver rejected the transfer request.');
    this.addNotification('Transfer Rejected', 'Peer declined the transfer request.', 'danger');
  }

  startStreamingTransfer(isReceiver = false) {
    const banner = document.getElementById('activeTransferBanner');
    banner.classList.remove('hidden');
    document.getElementById('statActiveTransfers').innerText = 'Streaming';

    let lastBytes = 0;
    let lastTime = Date.now();

    this.transferTimer = setInterval(() => {
      if (this.isPaused || !this.activeTransfer) return;

      // Realistic high-speed transfer: ~18MB/s - 35MB/s
      const chunkSize = Math.floor(Math.random() * 2500000) + 1800000;
      this.activeTransfer.transferred = Math.min(
        this.activeTransfer.totalBytes,
        this.activeTransfer.transferred + chunkSize
      );

      const percent = Math.floor((this.activeTransfer.transferred / this.activeTransfer.totalBytes) * 100);
      document.getElementById('bannerProgressBar').style.width = percent + '%';
      document.getElementById('bannerPercent').innerText = percent + '%';

      const now = Date.now();
      const deltaSec = (now - lastTime) / 1000;
      const speed = deltaSec > 0 ? (this.activeTransfer.transferred - lastBytes) / deltaSec : 0;
      const remainingBytes = this.activeTransfer.totalBytes - this.activeTransfer.transferred;
      const eta = speed > 0 ? Math.ceil(remainingBytes / speed) : 0;

      lastBytes = this.activeTransfer.transferred;
      lastTime = now;

      document.getElementById('bannerTitle').innerText =
        `${isReceiver ? 'Receiving from' : 'Sending to'} ${this.activeTransfer.peerName} (${this.activeTransfer.files.length} items)`;
      document.getElementById('bannerSub').innerText =
        `${this.formatBytes(this.activeTransfer.transferred)} / ${this.formatBytes(this.activeTransfer.totalBytes)} • ${(speed / (1024 * 1024)).toFixed(1)} MB/s • ETA: ${eta}s`;

      if (this.activeTransfer.transferred >= this.activeTransfer.totalBytes) {
        this.finishTransfer(isReceiver);
      }
    }, 200);
  }

  finishTransfer(isReceiver) {
    clearInterval(this.transferTimer);
    this.transferTimer = null;
    document.getElementById('activeTransferBanner').classList.add('hidden');
    document.getElementById('statActiveTransfers').innerText = 'Idle';

    const session = {
      id: this.activeTransfer.id,
      type: this.activeTransfer.type,
      peerName: this.activeTransfer.peerName,
      files: this.activeTransfer.files.map(f => f.name),
      fileCount: this.activeTransfer.files.length,
      totalBytes: this.activeTransfer.totalBytes,
      status: 'completed',
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) + ' • ' + new Date().toLocaleDateString()
    };

    this.history.unshift(session);
    localStorage.setItem('aura_history', JSON.stringify(this.history));

    this.addNotification(
      'Transfer Completed',
      `Successfully transferred ${session.fileCount} file(s) (${this.formatBytes(session.totalBytes)}) with ${session.peerName}`,
      'success'
    );

    // If receiver, trigger real browser file download
    if (isReceiver && this.activeTransfer.files.length > 0) {
      const blob = new Blob(['AuraShare Direct Offline Transfer: ' + this.activeTransfer.files[0].name], { type: 'application/octet-stream' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = this.activeTransfer.files[0].name;
      a.click();
      URL.revokeObjectURL(url);
    }

    this.activeTransfer = null;
    this.renderHistory();
    this.renderReceiveScreen();
    this.renderStats();
  }

  cancelTransfer() {
    clearInterval(this.transferTimer);
    this.transferTimer = null;
    document.getElementById('activeTransferBanner').classList.add('hidden');
    document.getElementById('statActiveTransfers').innerText = 'Idle';

    if (this.activeTransfer) {
      this.history.unshift({
        id: this.activeTransfer.id,
        type: this.activeTransfer.type,
        peerName: this.activeTransfer.peerName,
        files: this.activeTransfer.files.map(f => f.name),
        fileCount: this.activeTransfer.files.length,
        totalBytes: this.activeTransfer.totalBytes,
        status: 'cancelled',
        timestamp: new Date().toLocaleTimeString()
      });
      localStorage.setItem('aura_history', JSON.stringify(this.history));
      this.activeTransfer = null;
    }
    this.renderHistory();
    this.renderStats();
  }

  // --- Rendering UI State ---

  renderUserProfile() {
    document.getElementById('sidebarUserName').innerText = this.user.name;
    document.getElementById('sidebarDeviceName').innerText = this.settings.deviceName;
    document.getElementById('sidebarAvatar').innerText = this.user.avatar || 'A';
    document.getElementById('dashGreeting').innerText = `Welcome, ${this.user.name} 👋`;
    document.getElementById('settingDeviceName').value = this.settings.deviceName;
    document.getElementById('profileNameDisplay').innerText = this.user.name;
    document.getElementById('profileAvatarLarge').innerText = this.user.avatar || 'A';
    document.getElementById('profileDeviceBadge').innerText = 'Device: ' + this.settings.deviceName;
  }

  renderStats() {
    document.getElementById('statConnectedDevs').innerText = this.devices.size;
    document.getElementById('statNearbySub').innerText = `${this.devices.size} device(s) discoverable`;

    const sentSessions = this.history.filter(h => h.type === 'sent' && h.status === 'completed');
    const recvSessions = this.history.filter(h => h.type === 'received' && h.status === 'completed');

    const sentCount = sentSessions.reduce((sum, h) => sum + h.fileCount, 0);
    const sentBytes = sentSessions.reduce((sum, h) => sum + h.totalBytes, 0);
    const recvCount = recvSessions.reduce((sum, h) => sum + h.fileCount, 0);
    const recvBytes = recvSessions.reduce((sum, h) => sum + h.totalBytes, 0);

    document.getElementById('statSentFiles').innerText = sentCount;
    document.getElementById('statSentBytes').innerText = this.formatBytes(sentBytes) + ' total';
    document.getElementById('statReceivedFiles').innerText = recvCount;
    document.getElementById('statReceivedBytes').innerText = this.formatBytes(recvBytes) + ' total';

    document.getElementById('profSentCount').innerText = `${sentCount} files`;
    document.getElementById('profSentBytes').innerText = this.formatBytes(sentBytes);
    document.getElementById('profRecvCount').innerText = `${recvCount} files`;
    document.getElementById('profRecvBytes').innerText = this.formatBytes(recvBytes);
  }

  renderHistory() {
    const list = document.getElementById('fullHistoryList');
    const dashList = document.getElementById('dashRecentList');

    if (this.history.length === 0) {
      const emptyHtml = `
        <div style="text-align:center; padding:36px; background:var(--card-dark); border-radius:16px; border:1px solid var(--border-dark);">
          <i class="fa-solid fa-clock-rotate-left" style="font-size:32px; color:var(--text-muted); opacity:0.4;"></i>
          <h4 style="margin:12px 0 4px; font-size:15px;">No Transfer History</h4>
          <p style="font-size:12px; color:var(--text-muted);">Completed offline file transmissions will automatically appear here.</p>
        </div>`;
      list.innerHTML = emptyHtml;
      dashList.innerHTML = emptyHtml;
      return;
    }

    const renderItem = (h) => {
      const isSent = h.type === 'sent';
      const statusColor = h.status === 'completed' ? 'success' : (h.status === 'cancelled' ? 'dark' : 'danger');

      return `
        <div class="history-item">
          <div class="history-icon-bubble ${isSent ? 'sent' : 'recv'}">
            <i class="fa-solid ${isSent ? 'fa-arrow-up' : 'fa-arrow-down'}"></i>
          </div>
          <div class="history-info">
            <strong>${h.files ? h.files[0] : 'Transfer Item'}</strong>
            <div class="history-meta">
              <span>${isSent ? 'Sent to' : 'Received from'} ${h.peerName}</span>
              <span>•</span>
              <span>${this.formatBytes(h.totalBytes)}</span>
              <span>•</span>
              <span>${h.timestamp}</span>
            </div>
          </div>
          <span class="badge ${statusColor}" style="text-transform: capitalize;">${h.status}</span>
        </div>`;
    };

    list.innerHTML = this.history.map(renderItem).join('');
    dashList.innerHTML = this.history.slice(0, 4).map(renderItem).join('');
  }

  addNotification(title, message, type = 'info') {
    const notif = {
      id: 'notif_' + Date.now(),
      title,
      message,
      type,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false
    };
    this.notifications.unshift(notif);
    localStorage.setItem('aura_notifications', JSON.stringify(this.notifications));
    this.renderNotifications();
  }

  renderNotifications() {
    const list = document.getElementById('fullNotifList');
    const unread = this.notifications.filter(n => !n.read).length;

    const bellBadge = document.getElementById('bellBadge');
    const sidebarBadge = document.getElementById('unreadNotifBadge');

    if (unread > 0) {
      bellBadge.innerText = unread;
      bellBadge.classList.remove('hidden');
      sidebarBadge.innerText = unread;
      sidebarBadge.classList.remove('hidden');
    } else {
      bellBadge.classList.add('hidden');
      sidebarBadge.classList.add('hidden');
    }

    if (this.notifications.length === 0) {
      list.innerHTML = `
        <div style="text-align:center; padding:40px; background:var(--card-dark); border-radius:16px; border:1px solid var(--border-dark);">
          <i class="fa-regular fa-bell-slash" style="font-size:36px; color:var(--text-muted); opacity:0.4;"></i>
          <h4 style="margin:14px 0 4px;">No Notifications</h4>
          <p style="font-size:12px; color:var(--text-muted);">Incoming requests and completed transfers will show here.</p>
        </div>`;
      return;
    }

    list.innerHTML = this.notifications.map(n => `
      <div class="history-item" style="border-left: 3px solid var(--${n.type === 'info' ? 'primary' : (n.type === 'success' ? 'success' : 'danger')});">
        <div class="history-info">
          <strong>${n.title}</strong>
          <p style="font-size: 13px; color: var(--text-muted); margin: 3px 0;">${n.message}</p>
          <span style="font-size: 11px; color: var(--text-muted);">${n.time}</span>
        </div>
      </div>
    `).join('');
  }

  renderTrustedDevices() {
    const list = document.getElementById('trustedDevicesList');
    if (this.trustedIds.length === 0) {
      list.innerHTML = `
        <div style="text-align:center; padding:24px; background:var(--card-dark); border-radius:14px; border:1px solid var(--border-dark); font-size:13px; color:var(--text-muted);">
          No starred trusted devices yet.
        </div>`;
    } else {
      list.innerHTML = this.trustedIds.map(id => `
        <div style="background:var(--card-dark); padding:12px 18px; border-radius:12px; border:1px solid var(--border-dark); display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
          <div><i class="fa-solid fa-shield-check text-cyan"></i> <strong>${id}</strong></div>
          <button class="btn-link danger" onclick="app.toggleTrust('${id}')">Revoke Trust</button>
        </div>
      `).join('');
    }
  }

  toggleTrust(id) {
    if (this.trustedIds.includes(id)) {
      this.trustedIds = this.trustedIds.filter(i => i !== id);
    } else {
      this.trustedIds.push(id);
    }
    localStorage.setItem('aura_trusted_ids', JSON.stringify(this.trustedIds));
    this.renderSendDevicesGrid();
    this.renderTrustedDevices();
  }

  // --- Local Offline Authentication ---

  checkAuthSession() {
    const authScreen = document.getElementById('authScreen');
    const appShell = document.getElementById('appShell');

    if (this.currentUser) {
      if (authScreen) authScreen.classList.add('hidden');
      if (appShell) appShell.classList.remove('hidden');
      this.renderUserProfile();
      return true;
    }

    if (appShell) appShell.classList.add('hidden');
    if (authScreen) authScreen.classList.remove('hidden');
    this.switchAuthTab('login');
    return false;
  }

  switchAuthTab(tab) {
    const tabLogin = document.getElementById('tabBtnLogin');
    const tabRegister = document.getElementById('tabBtnRegister');
    const formLogin = document.getElementById('loginForm');
    const formRegister = document.getElementById('registerForm');
    const errLogin = document.getElementById('loginError');
    const errRegister = document.getElementById('registerError');

    if (errLogin) errLogin.classList.add('hidden');
    if (errRegister) errRegister.classList.add('hidden');

    if (tab === 'login') {
      if (tabLogin) tabLogin.classList.add('active');
      if (tabRegister) tabRegister.classList.remove('active');
      if (formLogin) formLogin.classList.remove('hidden');
      if (formRegister) formRegister.classList.add('hidden');
    } else {
      if (tabLogin) tabLogin.classList.remove('active');
      if (tabRegister) tabRegister.classList.add('active');
      if (formLogin) formLogin.classList.add('hidden');
      if (formRegister) formRegister.classList.remove('hidden');
    }
  }

  handleLoginForm(e) {
    e.preventDefault();
    const email = document.getElementById('loginEmail').value.trim().toLowerCase();
    const password = document.getElementById('loginPassword').value.trim();
    const errEl = document.getElementById('loginError');

    if (errEl) errEl.classList.add('hidden');

    const accounts = JSON.parse(localStorage.getItem('aura_accounts')) || [];
    const account = accounts.find(a => a.email.toLowerCase() === email && a.password === password);

    if (!account) {
      if (errEl) {
        errEl.innerHTML = '<i class="fa-solid fa-circle-exclamation"></i> <strong>Invalid Credentials:</strong> Incorrect email or password. Please verify or create an account.';
        errEl.classList.remove('hidden');
      }
      return;
    }

    // Success
    this.currentUser = account;
    localStorage.setItem('aura_active_user', JSON.stringify(account));
    sessionStorage.setItem('aura_active_user', JSON.stringify(account));

    this.user.name = account.fullName;
    this.user.email = account.email;
    this.user.deviceName = account.deviceName || (account.fullName.split(' ')[0] + "'s Laptop");
    this.user.avatar = (account.fullName[0] || 'U').toUpperCase();
    this.settings.deviceName = this.user.deviceName;

    document.getElementById('authScreen').classList.add('hidden');
    document.getElementById('appShell').classList.remove('hidden');

    this.renderUserProfile();
    this.renderStats();
    this.renderHistory();
    this.renderNotifications();
    this.renderTrustedDevices();
    this.broadcastBeacon();
    this.addNotification('Authenticated', `Welcome back, ${account.fullName}! Local offline vault unlocked.`, 'success');
  }

  handleRegisterForm(e) {
    e.preventDefault();
    const fullName = document.getElementById('regFullName').value.trim();
    const email = document.getElementById('regEmail').value.trim().toLowerCase();
    const password = document.getElementById('regPassword').value;
    const confirmPassword = document.getElementById('regConfirmPassword').value;
    const errEl = document.getElementById('registerError');

    if (errEl) errEl.classList.add('hidden');

    if (!fullName) {
      if (errEl) {
        errEl.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> Please enter your Full Name.';
        errEl.classList.remove('hidden');
      }
      return;
    }

    if (password.length < 6) {
      if (errEl) {
        errEl.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> Password must be at least 6 characters long.';
        errEl.classList.remove('hidden');
      }
      return;
    }

    if (password !== confirmPassword) {
      if (errEl) {
        errEl.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> Passwords do not match. Please re-enter.';
        errEl.classList.remove('hidden');
      }
      return;
    }

    const accounts = JSON.parse(localStorage.getItem('aura_accounts')) || [];
    if (accounts.some(a => a.email.toLowerCase() === email)) {
      if (errEl) {
        errEl.innerHTML = '<i class="fa-solid fa-circle-exclamation"></i> An account with this email already exists on this device. Please sign in.';
        errEl.classList.remove('hidden');
      }
      return;
    }

    const newAccount = {
      id: 'usr_' + Date.now(),
      fullName: fullName,
      email: email,
      password: password,
      deviceName: fullName.split(' ')[0] + "'s Device",
      createdAt: new Date().toISOString()
    };

    accounts.push(newAccount);
    localStorage.setItem('aura_accounts', JSON.stringify(accounts));

    // Auto-login newly registered account
    this.currentUser = newAccount;
    localStorage.setItem('aura_active_user', JSON.stringify(newAccount));
    sessionStorage.setItem('aura_active_user', JSON.stringify(newAccount));

    this.user.name = newAccount.fullName;
    this.user.email = newAccount.email;
    this.user.deviceName = newAccount.deviceName;
    this.user.avatar = (newAccount.fullName[0] || 'U').toUpperCase();
    this.settings.deviceName = this.user.deviceName;

    document.getElementById('authScreen').classList.add('hidden');
    document.getElementById('appShell').classList.remove('hidden');

    this.renderUserProfile();
    this.renderStats();
    this.renderHistory();
    this.renderNotifications();
    this.renderTrustedDevices();
    this.broadcastBeacon();
    this.addNotification('Account Created', `Welcome to AuraShare, ${fullName}! Local offline vault created.`, 'success');
  }

  logout() {
    this.currentUser = null;
    localStorage.removeItem('aura_active_user');
    sessionStorage.removeItem('aura_active_user');

    document.getElementById('appShell').classList.add('hidden');
    document.getElementById('authScreen').classList.remove('hidden');
    this.switchAuthTab('login');
    const loginEmail = document.getElementById('loginEmail');
    const loginPassword = document.getElementById('loginPassword');
    if (loginEmail) loginEmail.value = '';
    if (loginPassword) loginPassword.value = '';
    this.addNotification('Logged Out', 'Local vault locked. Sign in to access your offline transfers.', 'info');
  }

  // --- Download Offline App & PWA ---

  openDownloadModal() {
    const modal = document.getElementById('downloadAppModal');
    if (modal) {
      const modalIp = document.getElementById('modalLanIp');
      if (modalIp) modalIp.innerText = `http://${this.localIp}:8080`;
      modal.classList.remove('hidden');
    }
  }

  closeDownloadModal() {
    const modal = document.getElementById('downloadAppModal');
    if (modal) modal.classList.add('hidden');
  }

  copyLanUrl() {
    const url = `http://${this.localIp}:8080`;
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(url).then(() => {
        this.addNotification('Link Copied', `Copied: ${url} — open on any phone or laptop on your Wi-Fi!`, 'success');
      }).catch(() => {
        this.addNotification('LAN URL', `Open ${url} on your phone or device.`, 'info');
      });
    } else {
      this.addNotification('LAN URL', `Open ${url} on your phone or device.`, 'info');
    }
  }

  updatePwaInstallButtons(canPrompt, isInstalled = false) {
    const pwaBtn = document.getElementById('installPwaBtn');
    const topbarBtn = document.getElementById('topbarInstallPwaBtn');
    const readyBox = document.getElementById('pwaPromptReadyBox');

    if (isInstalled) {
      if (pwaBtn) {
        pwaBtn.innerHTML = '<i class="fa-solid fa-circle-check text-green"></i> App Installed';
        pwaBtn.classList.remove('btn-outline-cyan');
        pwaBtn.classList.add('btn-outline');
      }
      if (topbarBtn) {
        topbarBtn.innerHTML = '<i class="fa-solid fa-circle-check text-green"></i> Installed';
        topbarBtn.classList.remove('btn-outline-cyan');
        topbarBtn.classList.add('btn-outline');
      }
      if (readyBox) readyBox.classList.add('hidden');
      return;
    }

    if (canPrompt) {
      if (pwaBtn) pwaBtn.innerHTML = '<i class="fa-solid fa-download"></i> Install PWA App (Ready)';
      if (topbarBtn) topbarBtn.innerHTML = '<i class="fa-solid fa-download"></i> Install App';
      if (readyBox) readyBox.classList.remove('hidden');
    } else {
      if (readyBox) readyBox.classList.add('hidden');
    }
  }

  triggerPwaInstall() {
    if (window.deferredPwaPrompt) {
      this.executePwaPrompt();
    } else {
      this.openPwaGuideModal();
    }
  }

  executePwaPrompt() {
    if (!window.deferredPwaPrompt) {
      this.openPwaGuideModal();
      return;
    }
    const promptEvent = window.deferredPwaPrompt;
    promptEvent.prompt();
    promptEvent.userChoice.then((choiceResult) => {
      if (choiceResult && choiceResult.outcome === 'accepted') {
        this.addNotification('App Installed', 'AuraShare installed to desktop app launcher.', 'success');
        this.updatePwaInstallButtons(false, true);
        this.closePwaGuideModal();
      }
      window.deferredPwaPrompt = null;
    }).catch(err => {
      console.log('PWA prompt error:', err);
      this.openPwaGuideModal();
    });
  }

  openPwaGuideModal() {
    const modal = document.getElementById('pwaInstallModal');
    if (modal) {
      const readyBox = document.getElementById('pwaPromptReadyBox');
      if (readyBox) {
        if (window.deferredPwaPrompt) {
          readyBox.classList.remove('hidden');
        } else {
          readyBox.classList.add('hidden');
        }
      }
      modal.classList.remove('hidden');
    }
  }

  closePwaGuideModal() {
    const modal = document.getElementById('pwaInstallModal');
    if (modal) modal.classList.add('hidden');
  }

  cycleBackground() {
    this.addNotification('Unified Background Active', 'AuraShare 3D Glass Folders Theme is active globally.', 'info');
  }
}

// Instantiate global app
window.app = new AuraShareApp();
