import 'package:flutter/material.dart';
import '../theme.dart';

class ArchitectureScreen extends StatefulWidget {
  const ArchitectureScreen({super.key});

  @override
  State<ArchitectureScreen> createState() => _ArchitectureScreenState();
}

class _ArchitectureScreenState extends State<ArchitectureScreen> {
  int _selectedFlow = 0; // 0: None, 1: Train Search, 2: Ticket Booking, 3: PNR Status, 4: eWallet Pay

  final List<String> _flowTitles = [
    "Select a flow to inspect pipeline",
    "Train Search Pipeline (Peak 25K+ RPS)",
    "Ticket Booking Queue (Anti-Concurrency)",
    "PNR Status Cache (Heavy Read Path)",
    "eWallet Checkout (High Consistency)"
  ];

  final List<String> _flowExplanations = [
    "Tap any pipeline button above to inspect how the frontend client request traverses through DNS/CDNs, API Gateways, Microservices, Message Brokers, and Data Stores under high scalability.",
    "🚀 Peak search rate of 25K+ RPS is absorbed by routing requests to nearest CDN edge, validating credentials at the API Gateway, and running searches via the Train Search Service which reads cached schedules in Redis Cluster and station indices in Elasticsearch, fully bypassing disk DB queries.",
    "🎟️ During Tatkal booking surges, ticket requests are serialized via a Message Broker queue (Kafka/RabbitMQ) to prevent race conditions, guarantee FIFO booking, and throttle writes to the PostgreSQL Booking DB. This guarantees zero double-booking or transactional crashes.",
    "🔍 PNR status reads grow exponentially close to train departure times. The PNR Service fetches chart preparations from the transactional DB once, compiles them, and caches them in Redis with TTLs, rendering instant 2ms read latency for 10 Cr+ daily inquiries.",
    "💳 eWallet operations require strict ACID transaction compliance. Requests bypass queues and hit the eWallet Service, which communicates with User DBs and external Aadhaar/KYC services. Transactions are replicated in real-time to multi-AZ databases to ensure high availability and pci-compliance."
  ];

  // Helper to determine if a node is active in the selected flow
  bool _isNodeActive(String nodeName) {
    if (_selectedFlow == 0) return true; // All active by default when none selected
    
    switch (_selectedFlow) {
      case 1: // Train Search
        return ["Clients", "DNS/CDN", "API Gateway", "Search Service", "Cache (Redis)", "Search Index (ES)"].contains(nodeName);
      case 2: // Ticket Booking
        return ["Clients", "DNS/CDN", "API Gateway", "Booking Service", "Message Broker (Kafka)", "Booking DB (SQL)"].contains(nodeName);
      case 3: // PNR Status
        return ["Clients", "DNS/CDN", "API Gateway", "PNR Service", "Cache (Redis)"].contains(nodeName);
      case 4: // eWallet Checkout
        return ["Clients", "DNS/CDN", "API Gateway", "eWallet Service", "User DB (SQL)"].contains(nodeName);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SYSTEM DESIGN VIEWER")),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDarkNavy, AppTheme.backgroundDark],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro
              const Text(
                "SYSTEM INFRASTRUCTURE MAPPING",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.goldAccent),
              ),
              const SizedBox(height: 4),
              const Text(
                "This visualizer demonstrates the backend microservices architecture supporting the IRCTC APP as per the provided system design blueprint.",
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // Pipeline Flow Selection Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFlowButton(1, "Search Flow", Icons.search_rounded),
                    _buildFlowButton(2, "Booking Flow", Icons.confirmation_number_rounded),
                    _buildFlowButton(3, "PNR Flow", Icons.receipt_long_rounded),
                    _buildFlowButton(4, "eWallet Flow", Icons.account_balance_wallet_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Interactive Flow Chart Diagram Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryLightNavy),
                ),
                child: Column(
                  children: [
                    // Row 1: Clients
                    _buildDiagramNode("Clients", "Android, iOS, Web App, Partners", Colors.blueAccent),
                    _buildDownArrow("Clients", "DNS/CDN"),

                    // Row 2: CDN
                    _buildDiagramNode("DNS/CDN", "Cloudflare Edge - Routing & Static Caching", Colors.tealAccent),
                    _buildDownArrow("DNS/CDN", "API Gateway"),

                    // Row 3: API Gateway
                    _buildDiagramNode("API Gateway", "Rate Limiting | Auth | Request Validation", Colors.purpleAccent),
                    
                    // Splits
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_downward_rounded, color: AppTheme.goldAccent, size: 16),
                        const SizedBox(width: 80),
                        const Icon(Icons.arrow_downward_rounded, color: AppTheme.goldAccent, size: 16),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 4: Microservices Split
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildDiagramNode("Search Service", "Train Availability Schedules", AppTheme.goldAccent),
                              _buildDownArrow("Search Service", "Cache (Redis)"),
                              _buildDiagramNode("Cache (Redis)", "Redis Cluster - RAM Storage", Colors.pinkAccent),
                              _buildDownArrow("Cache (Redis)", "Search Index (ES)"),
                              _buildDiagramNode("Search Index (ES)", "Elasticsearch Query Optimization", Colors.orangeAccent),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _buildDiagramNode("Booking Service", "Passenger Seats Allocation", Colors.greenAccent),
                              _buildDownArrow("Booking Service", "Message Broker (Kafka)"),
                              _buildDiagramNode("Message Broker (Kafka)", "FIFO Queue Async Buffer", Colors.cyanAccent),
                              _buildDownArrow("Message Broker (Kafka)", "Booking DB (SQL)"),
                              _buildDiagramNode("Booking DB (SQL)", "PostgreSQL Master-Replica", Colors.indigoAccent),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    // Row 5: Central DB & Support services
                    Row(
                      children: [
                        Expanded(child: _buildDiagramNode("PNR Service", "Seat Manifest Chart Maker", Colors.purpleAccent)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDiagramNode("eWallet Service", "Ledger Transaction Registry", AppTheme.goldAccent)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildDiagramNode("User DB (SQL)", "User Profile Accounts DB", Colors.blueAccent)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Explanation Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedFlow != 0 ? AppTheme.goldAccent.withOpacity(0.08) : AppTheme.cardNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFlow != 0 ? AppTheme.goldAccent : AppTheme.primaryLightNavy,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _flowTitles[_selectedFlow],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.goldAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _flowExplanations[_selectedFlow],
                      style: const TextStyle(fontSize: 12, height: 1.5, color: AppTheme.textWhite),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              
              // Key Consideration Stat Cards
              const Text(
                "SYSTEM LOAD ESTIMATES",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.goldAccent),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _buildStatCard("DAU", "1.5 Cr+", "Active users/day")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Bookings", "20 Lakh+", "Tickets/day")),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard("Peak RPS", "25K+", "Requests/second")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard("Avail. Checks", "10 Cr+", "Searches/day")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlowButton(int flowIndex, String label, IconData icon) {
    final isSelected = _selectedFlow == flowIndex;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _selectedFlow = _selectedFlow == flowIndex ? 0 : flowIndex;
          });
        },
        icon: Icon(icon, size: 14, color: isSelected ? AppTheme.primaryNavy : AppTheme.goldAccent),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.goldAccent : AppTheme.cardNavy,
          foregroundColor: isSelected ? AppTheme.primaryNavy : AppTheme.textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: BorderSide(color: isSelected ? AppTheme.goldAccent : AppTheme.primaryLightNavy),
        ),
      ),
    );
  }

  Widget _buildDiagramNode(String name, String subText, Color accentColor) {
    final isActive = _isNodeActive(name);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isActive ? 1.0 : 0.22,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive && _selectedFlow != 0 ? AppTheme.goldAccent : AppTheme.primaryLightNavy,
            width: isActive && _selectedFlow != 0 ? 2 : 1,
          ),
          boxShadow: isActive && _selectedFlow != 0
              ? [
                  BoxShadow(
                    color: AppTheme.goldAccent.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isActive ? AppTheme.textWhite : AppTheme.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: isActive ? AppTheme.textMuted : AppTheme.textMuted.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownArrow(String topNode, String bottomNode) {
    final bool isLineActive = _isNodeActive(topNode) && _isNodeActive(bottomNode);
    return Opacity(
      opacity: isLineActive ? 1.0 : 0.22,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        child: Icon(Icons.arrow_downward_rounded, color: AppTheme.goldAccent, size: 16),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}
