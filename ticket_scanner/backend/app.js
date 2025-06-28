const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Valid QR ticket codes hashmap/dictionary
// Key: base64 encoded string, Value: ticket information
const VALID_TICKETS = {
  'QUJDLWFiYy0xMjM0': {
    id: 'ABC-abc-1234',
    type: 'VIP Concert Ticket',
    event: 'Summer Music Festival 2024',
    section: 'VIP Area',
    seat: 'A-15',
    price: 150.00,
    holderName: 'John Doe',
    issueDate: '2024-01-15T10:30:00Z',
    eventDate: '2024-07-20T19:00:00Z',
    venue: 'City Concert Hall',
    status: 'active'
  },
  'QUJDLWFiYy0xMjM1': {
    id: 'ABC-abc-1235',
    type: 'VIP Concert Ticket',
    event: 'Summer Music Festival 2025',
    section: 'VIP Area',
    seat: 'A-15',
    price: 150.00,
    holderName: 'John Doe',
    issueDate: '2024-01-15T10:30:00Z',
    eventDate: '2024-07-20T19:00:00Z',
    venue: 'City Concert Hall',
    status: 'active'
  },
  'QUJDLWFiYy0xMjM2': {
    id: 'ABC-abc-1236',
    type: 'VIP Concert Ticket',
    event: 'Summer Music Festival 2026',
    section: 'VIP Area',
    seat: 'A-15',
    price: 150.00,
    holderName: 'John Doe',
    issueDate: '2024-01-15T10:30:00Z',
    eventDate: '2024-07-20T19:00:00Z',
    venue: 'City Concert Hall',
    status: 'active'
  },
  // Add more valid tickets here
  'REVGLWRlZi01Njc4': {
    id: 'DEF-def-5678',
    type: 'General Admission',
    event: 'Summer Music Festival 2024',
    section: 'General',
    seat: 'GA-001',
    price: 75.00,
    holderName: 'Jane Smith',
    issueDate: '2024-01-16T14:20:00Z',
    eventDate: '2024-07-20T19:00:00Z',
    venue: 'City Concert Hall',
    status: 'active'
  },
  'R0hJLWdoaS05MDEy': {
    id: 'GHI-ghi-9012',
    type: 'Premium Seating',
    event: 'Summer Music Festival 2024',
    section: 'Premium',
    seat: 'P-25',
    price: 120.00,
    holderName: 'Mike Johnson',
    issueDate: '2024-01-17T09:45:00Z',
    eventDate: '2024-07-20T19:00:00Z',
    venue: 'City Concert Hall',
    status: 'active'
  }
};

// Used tickets tracking (to prevent double scanning)
const USED_TICKETS = new Set();

// Utility function to decode base64
function decodeBase64(encodedString) {
  try {
    return Buffer.from(encodedString, 'base64').toString('utf-8');
  } catch (error) {
    return null;
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'Ticket Validation API',
    totalValidTickets: Object.keys(VALID_TICKETS).length,
    usedTickets: USED_TICKETS.size
  });
});

// Main ticket validation endpoint
app.post('/validate-ticket', (req, res) => {
  const { ticketCode } = req.body;
  
  if (!ticketCode) {
    return res.status(400).json({
      success: false,
      error: 'Ticket code is required',
      code: 'MISSING_TICKET_CODE'
    });
  }
  
  // Check if the exact QR string exists in our valid tickets hashmap
  if (!VALID_TICKETS[ticketCode]) {
    return res.status(404).json({
      success: false,
      error: 'Ticket not found or invalid',
      code: 'TICKET_NOT_FOUND',
      receivedCode: ticketCode
    });
  }
  
  // Check if ticket has already been used
  if (USED_TICKETS.has(ticketCode)) {
    return res.status(409).json({
      success: false,
      error: 'Ticket has already been scanned',
      code: 'TICKET_ALREADY_USED',
      ticketInfo: VALID_TICKETS[ticketCode]
    });
  }
  
  // Mark ticket as used
  USED_TICKETS.add(ticketCode);
  
  // Get ticket information
  const ticketInfo = VALID_TICKETS[ticketCode];
  
  // Success response
  res.json({
    success: true,
    message: 'Ticket is valid and has been scanned',
    ticketInfo: {
      ...ticketInfo,
      scannedAt: new Date().toISOString(),
      qrCode: ticketCode
    }
  });
});

// GET endpoint for quick validation (for testing)
app.get('/validate-ticket/:ticketCode', (req, res) => {
  const { ticketCode } = req.params;
  
  // Check if the exact QR string exists in our valid tickets hashmap
  if (!VALID_TICKETS[ticketCode]) {
    return res.status(404).json({
      success: false,
      error: 'Ticket not found or invalid',
      code: 'TICKET_NOT_FOUND',
      receivedCode: ticketCode
    });
  }
  
  // Check if ticket has already been used
  if (USED_TICKETS.has(ticketCode)) {
    return res.status(409).json({
      success: false,
      error: 'Ticket has already been scanned',
      code: 'TICKET_ALREADY_USED',
      ticketInfo: VALID_TICKETS[ticketCode]
    });
  }
  
  // Mark ticket as used
  USED_TICKETS.add(ticketCode);
  
  // Get ticket information
  const ticketInfo = VALID_TICKETS[ticketCode];
  
  // Success response
  res.json({
    success: true,
    message: 'Ticket is valid and has been scanned',
    ticketInfo: {
      ...ticketInfo,
      scannedAt: new Date().toISOString(),
      qrCode: ticketCode
    }
  });
});

// Check ticket status without marking as used (for preview)
app.get('/check-ticket/:ticketCode', (req, res) => {
  const { ticketCode } = req.params;
  
  // Check if the exact QR string exists in our valid tickets hashmap
  if (!VALID_TICKETS[ticketCode]) {
    return res.status(404).json({
      success: false,
      error: 'Ticket not found or invalid',
      code: 'TICKET_NOT_FOUND',
      receivedCode: ticketCode
    });
  }
  
  const ticketInfo = VALID_TICKETS[ticketCode];
  const isUsed = USED_TICKETS.has(ticketCode);
  
  res.json({
    success: true,
    message: 'Ticket found',
    ticketInfo: {
      ...ticketInfo,
      qrCode: ticketCode,
      isUsed: isUsed,
      checkedAt: new Date().toISOString()
    }
  });
});

// Reset ticket usage (admin endpoint)
app.post('/reset-ticket/:ticketCode', (req, res) => {
  const { ticketCode } = req.params;
  
  if (!VALID_TICKETS[ticketCode]) {
    return res.status(404).json({
      success: false,
      error: 'Ticket not found',
      code: 'TICKET_NOT_FOUND'
    });
  }
  
  USED_TICKETS.delete(ticketCode);
  
  res.json({
    success: true,
    message: 'Ticket usage reset successfully',
    ticketCode: ticketCode
  });
});

// Get all valid ticket codes (admin endpoint)
app.get('/admin/tickets', (req, res) => {
  const tickets = Object.keys(VALID_TICKETS).map(qrCode => ({
    qrCode,
    ...VALID_TICKETS[qrCode],
    isUsed: USED_TICKETS.has(qrCode)
  }));
  
  res.json({
    success: true,
    totalTickets: tickets.length,
    usedTickets: USED_TICKETS.size,
    tickets
  });
});

// Test endpoint to decode any base64 string (for debugging)
app.get('/decode/:encodedString', (req, res) => {
  const { encodedString } = req.params;
  const decoded = decodeBase64(encodedString);
  
  res.json({
    encoded: encodedString,
    decoded: decoded || 'Unable to decode',
    isValidTicket: !!VALID_TICKETS[encodedString],
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    code: 'NOT_FOUND'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Internal server error',
    code: 'SERVER_ERROR'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🎫 Ticket Validation API running on port ${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/health`);
  console.log(`🔍 Test ticket validation: http://localhost:${PORT}/validate-ticket/QUJDLWFiYy0xMjM0`);
  console.log(`📊 Admin tickets view: http://localhost:${PORT}/admin/tickets`);
  console.log(`\n📋 Available Endpoints:`);
  console.log(`   POST /validate-ticket - Validate and mark ticket as used`);
  console.log(`   GET  /validate-ticket/:code - Quick validation (marks as used)`);
  console.log(`   GET  /check-ticket/:code - Check status without marking as used`);
  console.log(`   POST /reset-ticket/:code - Reset ticket usage`);
  console.log(`   GET  /admin/tickets - View all tickets`);
  console.log(`   GET  /decode/:code - Decode base64 string`);
});

module.exports = app;
