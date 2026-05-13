const express = require('express');
const cors    = require('cors');
const qrcode  = require('qrcode');
const { Client, LocalAuth } = require('whatsapp-web.js');

const app  = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// ──────────────────────────────────────────────
// State
// ──────────────────────────────────────────────
const state = {
    status: 'connecting',  // connecting | qr | ready | auth_failure
    qrDataUrl: null,
    phoneNumber: null,
    messages: [],          // last 100 incoming messages
    chats: [],             // cached chat list
};

// ──────────────────────────────────────────────
// WhatsApp client
// ──────────────────────────────────────────────
const client = new Client({
    authStrategy: new LocalAuth({ dataPath: '.wwebjs_auth' }),
    puppeteer: {
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
        ],
    },
});

client.on('qr', async (qr) => {
    console.log('[WhatsApp] QR received — scan with your phone');
    state.status    = 'qr';
    state.qrDataUrl = await qrcode.toDataURL(qr);
});

client.on('authenticated', () => {
    console.log('[WhatsApp] Authenticated');
    state.status    = 'authenticated';
    state.qrDataUrl = null;
});

client.on('ready', async () => {
    console.log('[WhatsApp] Client ready');
    state.status = 'ready';

    const info = client.info;
    state.phoneNumber = info?.wid?.user || null;
    console.log(`[WhatsApp] Connected as ${state.phoneNumber}`);

    await refreshChats();
});

client.on('auth_failure', (msg) => {
    console.error('[WhatsApp] Auth failure:', msg);
    state.status    = 'auth_failure';
    state.qrDataUrl = null;
});

client.on('disconnected', (reason) => {
    console.warn('[WhatsApp] Disconnected:', reason);
    state.status      = 'connecting';
    state.phoneNumber = null;
    state.chats       = [];
});

client.on('message', (msg) => {
    const entry = {
        id:        msg.id._serialized,
        body:      msg.body,
        from:      msg.from,
        fromMe:    msg.fromMe,
        timestamp: msg.timestamp,
        chatId:    msg.from,
    };
    state.messages.unshift(entry);
    if (state.messages.length > 100) state.messages.pop();
    console.log(`[WhatsApp] Message from ${msg.from}: ${msg.body.slice(0, 60)}`);
});

// ──────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────
async function refreshChats() {
    try {
        const chats = await client.getChats();
        state.chats = chats.map(c => ({
            id:          c.id._serialized,
            name:        c.name || c.id.user,
            isGroup:     c.isGroup,
            unreadCount: c.unreadCount,
            lastMessage: c.lastMessage?.body?.slice(0, 80) || '',
            timestamp:   c.lastMessage?.timestamp || 0,
        })).sort((a, b) => b.timestamp - a.timestamp).slice(0, 50);
    } catch (err) {
        console.error('[WhatsApp] refreshChats error:', err.message);
    }
}

async function requireReady(res) {
    if (state.status !== 'ready') {
        res.status(503).json({ error: 'WhatsApp not connected', status: state.status });
        return false;
    }
    return true;
}

function buildReport(type, data) {
    const now = new Date();
    const dateStr = now.toLocaleDateString('he-IL', { year: 'numeric', month: 'long', day: 'numeric' });
    const timeStr = now.toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' });
    const line    = '═'.repeat(34);

    const PRIO  = { critical: 'קריטי 🔴', high: 'גבוה 🟠', normal: 'רגיל 🔵', low: 'נמוך ⚪' };
    const AVAIL = { available: 'זמין ✅', field: 'בשטח 🟡', leave: 'חופשה ⚪', reserves: 'מילואים 🟣', unavailable: 'לא זמין 🔴' };
    const TYPE  = { meeting: 'פגישה', training: 'אימון', visit: 'ביקור מפקד', operation: 'מבצע', admin: 'מנהלתי' };

    const sameDay = (ts, d) => {
        const a = new Date(ts); return a.getFullYear() === d.getFullYear() && a.getMonth() === d.getMonth() && a.getDate() === d.getDate();
    };

    const fmtTime = (dt) => new Date(dt).toLocaleTimeString('he-IL', { hour: '2-digit', minute: '2-digit' });

    let text = '';

    if (type === 'daily') {
        const tasks  = data.tasks  || [];
        const events = data.events || [];
        const todayEv= events.filter(e => sameDay(new Date(e.startDateTime), now))
                             .sort((a, b) => new Date(a.startDateTime) - new Date(b.startDateTime));
        const crit   = tasks.filter(t => t.priority === 'critical' && t.status !== 'done');
        const open   = tasks.filter(t => t.status !== 'done');

        text  = `🦅 *דיווח יומי — מח"ט גבעתי*\n`;
        text += `📅 ${dateStr} | ${timeStr}\n${line}\n\n`;
        text += `📋 *אירועים היום (${todayEv.length}):*\n`;
        todayEv.length ? todayEv.forEach(e => { text += `  • ${fmtTime(e.startDateTime)} — ${e.title}`; if (e.location) text += ` (${e.location})`; text += '\n'; }) : (text += '  אין אירועים\n');
        text += `\n🔴 *משימות קריטיות פתוחות (${crit.length}):*\n`;
        crit.length ? crit.forEach(t => { text += `  • ${t.title} | ${t.assignee || '—'} | יעד: ${t.dueDate || 'לא נקבע'}\n`; }) : (text += '  אין\n');
        text += `\n📊 *סה"כ פתוחות:* ${open.length} | *קריטיות:* ${crit.length}\n`;
        text += `\n_נשלח מ-מערכת ניהול מח"ט_`;
    }

    else if (type === 'personnel') {
        const personnel = data.personnel || [];
        const avail = personnel.filter(p => p.availability === 'available').length;

        text  = `🦅 *דיווח כוח אדם — מח"ט גבעתי*\n`;
        text += `📅 ${dateStr} | ${timeStr}\n${line}\n\n`;
        text += `👥 *סה"כ:* ${personnel.length} | *זמינים:* ${avail} | *לא זמינים:* ${personnel.length - avail}\n\n`;

        const byUnit = {};
        personnel.forEach(p => { (byUnit[p.unit] = byUnit[p.unit] || []).push(p); });
        Object.entries(byUnit).forEach(([unit, ppl]) => {
            text += `📌 *${unit}:*\n`;
            ppl.forEach(p => { text += `  ${p.rank} ${p.name} — ${AVAIL[p.availability] || p.availability}\n`; });
            text += '\n';
        });
        text += `_נשלח מ-מערכת ניהול מח"ט_`;
    }

    else if (type === 'readiness') {
        const units = data.units || [];
        const avg   = units.length ? Math.round(units.reduce((s, u) => s + u.readiness, 0) / units.length) : 0;

        text  = `🦅 *דיווח קריאות — מח"ט גבעתי*\n`;
        text += `📅 ${dateStr} | ${timeStr}\n${line}\n\n`;
        units.forEach(u => {
            const bar   = '█'.repeat(Math.floor(u.readiness / 10)) + '░'.repeat(10 - Math.floor(u.readiness / 10));
            const emoji = u.readiness >= 85 ? '✅' : u.readiness >= 65 ? '⚠️' : '🔴';
            text += `${emoji} *${u.name}* ${bar} ${u.readiness}%\n   מ"פ: ${u.cmd} | ${u.size} חיילים\n\n`;
        });
        text += `${line}\n🎯 *ממוצע קריאות מח"ט: ${avg}%*\n`;
        text += `\n_נשלח מ-מערכת ניהול מח"ט_`;
    }

    else if (type === 'tasks') {
        const tasks  = data.tasks || [];
        const open   = tasks.filter(t => t.status === 'open');
        const inProg = tasks.filter(t => t.status === 'in-progress');
        const done   = tasks.filter(t => t.status === 'done');
        const crit   = tasks.filter(t => t.priority === 'critical' && t.status !== 'done');

        text  = `🦅 *דיווח משימות — מח"ט גבעתי*\n`;
        text += `📅 ${dateStr} | ${timeStr}\n${line}\n\n`;
        text += `📊 פתוחות: ${open.length} | בביצוע: ${inProg.length} | הושלמו: ${done.length}\n\n`;
        if (crit.length) {
            text += `🔴 *קריטיות דחופות:*\n`;
            crit.forEach(t => { text += `  • ${t.title}\n    ${t.assignee || '—'} | יעד: ${t.dueDate || '—'}\n`; });
            text += '\n';
        }
        [...open, ...inProg].sort((a, b) => (a.dueDate || '') < (b.dueDate || '') ? -1 : 1).slice(0, 8).forEach(t => {
            text += `  [${PRIO[t.priority] || t.priority}] ${t.title} — ${t.assignee || '—'}\n`;
        });
        text += `\n_נשלח מ-מערכת ניהול מח"ט_`;
    }

    return text;
}

// ──────────────────────────────────────────────
// REST API
// ──────────────────────────────────────────────

// Status
app.get('/api/status', (req, res) => {
    res.json({
        status:      state.status,
        phoneNumber: state.phoneNumber,
        chatsCount:  state.chats.length,
        msgCount:    state.messages.length,
    });
});

// QR code
app.get('/api/qr', (req, res) => {
    if (state.status !== 'qr') {
        return res.status(400).json({ error: 'No QR available', status: state.status });
    }
    res.json({ qr: state.qrDataUrl });
});

// Chat list
app.get('/api/chats', async (req, res) => {
    if (!await requireReady(res)) return;
    await refreshChats();
    res.json(state.chats);
});

// Recent messages (incoming)
app.get('/api/messages', (req, res) => {
    const limit = parseInt(req.query.limit) || 30;
    res.json(state.messages.slice(0, limit));
});

// Messages from specific chat
app.get('/api/messages/:chatId', async (req, res) => {
    if (!await requireReady(res)) return;
    try {
        const chat    = await client.getChatById(req.params.chatId);
        const msgs    = await chat.fetchMessages({ limit: parseInt(req.query.limit) || 30 });
        const result  = msgs.map(m => ({
            id:        m.id._serialized,
            body:      m.body,
            fromMe:    m.fromMe,
            timestamp: m.timestamp,
            from:      m.from,
        }));
        res.json(result);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Send message
app.post('/api/send', async (req, res) => {
    if (!await requireReady(res)) return;
    const { chatId, message } = req.body;
    if (!chatId || !message) return res.status(400).json({ error: 'chatId and message required' });
    try {
        const msg = await client.sendMessage(chatId, message);
        res.json({ success: true, messageId: msg.id._serialized });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Send report
app.post('/api/send-report', async (req, res) => {
    if (!await requireReady(res)) return;
    const { chatId, type, data } = req.body;
    if (!chatId || !type || !data) return res.status(400).json({ error: 'chatId, type and data required' });

    const text = buildReport(type, data);
    if (!text) return res.status(400).json({ error: 'Unknown report type' });

    try {
        const msg = await client.sendMessage(chatId, text);
        res.json({ success: true, messageId: msg.id._serialized });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Logout
app.post('/api/logout', async (req, res) => {
    try {
        await client.logout();
        state.status      = 'connecting';
        state.phoneNumber = null;
        state.chats       = [];
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Health check
app.get('/health', (req, res) => res.json({ ok: true }));

// ──────────────────────────────────────────────
// Start
// ──────────────────────────────────────────────
app.listen(PORT, () => {
    console.log(`[Server] Givati WhatsApp server running on http://localhost:${PORT}`);
    console.log('[Server] Initializing WhatsApp client...');
    client.initialize().catch(err => console.error('[WhatsApp] Init error:', err));
});
