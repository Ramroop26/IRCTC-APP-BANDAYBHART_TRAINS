import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/train_service.dart';
import '../models/train.dart';
import '../theme.dart';

// ── All Indian Railways classes with their full names ──────────────────────
const Map<String, String> kClassNames = {
  'GN':  'General (GN)',
  'SL':  'Sleeper (SL)',
  '3A':  'AC 3 Tier (3A)',
  '2A':  'AC 2 Tier (2A)',
  '1A':  'First AC (1A)',
  'CC':  'AC Chair Car (CC)',
  'EC':  'Executive Chair (EC)',
  'EA':  'Executive Anubhuti (EA)',
  '2S':  '2nd Sitting (2S)',
  'FC':  'First Class (FC)',
};

// ── Comprehensive station list ─────────────────────────────────────────────
const List<String> kAllStations = [
  'New Delhi (NDLS)',
  'Hazrat Nizamuddin (NZM)',
  'Old Delhi (DLI)',
  'Anand Vihar (ANVT)',
  'Mumbai Central (MMCT)',
  'Chhatrapati Shivaji Terminus (CSMT)',
  'Lokmanya Tilak Terminus (LTT)',
  'Howrah (HWH)',
  'Sealdah (SDAH)',
  'Kolkata (KOAA)',
  'Chennai Central (MAS)',
  'Chennai Egmore (MS)',
  'Varanasi (BSB)',
  'Prayagraj (PRYJ)',
  'Kanpur Central (CNB)',
  'Lucknow Charbagh (LKO)',
  'Bhopal Jn (BPL)',
  'Nagpur Jn (NGP)',
  'Pune Jn (PUNE)',
  'Secunderabad Jn (SC)',
  'Hyderabad Deccan (HYB)',
  'Bengaluru City (SBC)',
  'Mysuru Jn (MYS)',
  'Thiruvananthapuram (TVC)',
  'Kochi (ERS)',
  'Patna Jn (PNBE)',
  'Gaya Jn (GAYA)',
  'Ahmedabad Jn (ADI)',
  'Surat (ST)',
  'Vadodara Jn (BRC)',
  'Jaipur Jn (JP)',
  'Jodhpur Jn (JU)',
  'Amritsar Jn (ASR)',
  'Chandigarh (CDG)',
  'Jammu Tawi (JAT)',
  'Agra Cantt (AGC)',
  'Mathura Jn (MTJ)',
  'Gwalior Jn (GWL)',
  'Jhansi Jn (VGLJ)',
  'Indore Jn (INDB)',
  'Ratlam Jn (RTM)',
  'Bhubaneswar (BBS)',
  'Visakhapatnam (VSKP)',
  'Vijayawada Jn (BZA)',
  'Tirupati (TPTY)',
  'Coimbatore Jn (CBE)',
  'Madurai Jn (MDU)',
  'New Jalpaiguri (NJP)',
  'Guwahati (GHY)',
  'Dibrugarh (DBRG)',
  'Ranchi (RNC)',
  'Dhanbad Jn (DHN)',
  'Raipur Jn (R)',
  'Bilaspur Jn (BSP)',
  'Gondia Jn (G)',
  'Kota Jn (KOTA)',
  'Ajmer Jn (AII)',
  'Bikaner Jn (BKN)',
  'Gandhinagar Cap (GNC)',
  'Rajkot Jn (RJT)',
  'Bhavnagar (BVP)',
  'Pt DD Upadhyaya (DDU)',
  'Asansol Jn (ASN)',
  'Kharagpur Jn (KGP)',
  'Puri (PURI)',
  'Cuttack Jn (CTC)',
  'Tatanagar Jn (TATA)',
  'KSR Bengaluru (SBC)',
  'Yesvantpur Jn (YPR)',
  'Hubli Jn (UBL)',
  'Mangaluru Jn (MAQ)',
  'Salem Jn (SA)',
  'Ernakulam Jn (ERS)',
  'Thrissur (TCR)',
  'Palakkad Jn (PGT)',
];

class TrainSearchScreen extends StatefulWidget {
  const TrainSearchScreen({super.key});
  @override
  State<TrainSearchScreen> createState() => _TrainSearchScreenState();
}

class _TrainSearchScreenState extends State<TrainSearchScreen>
    with SingleTickerProviderStateMixin {
  final TrainService _trainService = TrainService();

  // ── Tab state ──────────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── Station search fields ─────────────────────────────────────────────────
  final TextEditingController _fromCtrl = TextEditingController(text: 'New Delhi (NDLS)');
  final TextEditingController _toCtrl   = TextEditingController(text: 'Varanasi (BSB)');
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus   = FocusNode();

  // ── Train number search ────────────────────────────────────────────────────
  final TextEditingController _trainNumCtrl = TextEditingController();

  // ── Filters ────────────────────────────────────────────────────────────────
  DateTime _journeyDate = DateTime.now().add(const Duration(days: 1));
  String   _quota       = 'General';
  final Set<String> _selectedClasses = {};
  bool _hideFares = false;

  final List<String> _quotas = ['General', 'Ladies', 'Tatkal', 'Premium Tatkal', 'Senior Citizen'];

  // ── Results ─────────────────────────────────────────────────────────────────
  List<Train> _searchResults = [];
  List<Train> _trainNumResults = [];
  bool        _hasSearched   = false;
  bool        _isLoading     = false;
  String?     _trainNumError;

  // ── Auto-suggest overlay ─────────────────────────────────────────────────
  List<String> _fromSuggestions = [];
  List<String> _toSuggestions   = [];
  bool _showFromSugg = false;
  bool _showToSugg   = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fromFocus.addListener(() {
      if (!_fromFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showFromSugg = false);
        });
      }
    });
    _toFocus.addListener(() {
      if (!_toFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showToSugg = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    _trainNumCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<String> _filterStations(String query) {
    if (query.isEmpty) return kAllStations.take(8).toList();
    final q = query.toLowerCase();
    return kAllStations
        .where((s) => s.toLowerCase().contains(q))
        .take(6)
        .toList();
  }

  void _swapStations() {
    final tmp = _fromCtrl.text;
    setState(() {
      _fromCtrl.text = _toCtrl.text;
      _toCtrl.text   = tmp;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _journeyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.goldAccent,
            onPrimary: AppTheme.primaryNavy,
            surface: AppTheme.cardNavy,
            onSurface: AppTheme.textWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _journeyDate = picked);
  }

  // ── Station search & results ──────────────────────────────────────────────
  void _performStationSearch() {
    final src  = _fromCtrl.text.trim();
    final dest = _toCtrl.text.trim();
    if (src.isEmpty || dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter From and To stations.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }
    if (src == dest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Source and Destination cannot be the same!'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _hasSearched = true; _showFromSugg = false; _showToSugg = false; });
    Future.delayed(const Duration(milliseconds: 900), () {
      final results = _trainService.searchTrains(src, dest, _journeyDate);
      setState(() { _searchResults = results; _isLoading = false; });
    });
  }

  // ── Train number/name search ───────────────────────────────────────────────
  void _performTrainNumSearch() {
    final query = _trainNumCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a train number or name.'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _trainNumResults = []; _trainNumError = null; _hasSearched = true; });
    Future.delayed(const Duration(milliseconds: 600), () {
      final all = _trainService.getAllTrains();
      final matches = all.where((t) {
        return t.number.contains(query) || t.name.toLowerCase().contains(query);
      }).toList();
      setState(() {
        _isLoading = false;
        if (matches.isEmpty) {
          _trainNumError = 'No train found matching "$query" in database.';
          _trainNumResults = [];
        } else {
          _trainNumResults = matches;
          _trainNumError  = null;
        }
      });
    });
  }

  // ── Filtered results (by selected classes) ────────────────────────────────
  List<Train> get _filteredResults {
    if (_selectedClasses.isEmpty) return _searchResults;
    return _searchResults.where((t) {
      return t.classes.any((c) => _selectedClasses.contains(c));
    }).toList();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SEARCH TRAINS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldAccent,
          labelColor: AppTheme.goldAccent,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
          tabs: const [
            Tab(text: 'BY STATION'),
            Tab(text: 'BY TRAIN NO. / NAME'),
          ],
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDarkNavy, AppTheme.backgroundDark],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildStationSearchTab(),
            _buildTrainNumberTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1 – BY STATION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStationSearchTab() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() { _showFromSugg = false; _showToSugg = false; });
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Search Card ────────────────────────────────────────────────
            _buildSearchCard(),
            const SizedBox(height: 16),

            // ── Class Filter Row ───────────────────────────────────────────
            _buildClassFilterRow(),
            const SizedBox(height: 8),

            // ── Hide Fares & Quota ─────────────────────────────────────────
            _buildOptionsRow(),
            const SizedBox(height: 20),

            // ── FIND TRAINS button ─────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _performStationSearch,
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text('FIND TRAINS'),
            ),
            const SizedBox(height: 24),

            // ── Results ────────────────────────────────────────────────────
            if (_isLoading && _tabController.index == 0)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppTheme.goldAccent),
              ))
            else if (_hasSearched && _tabController.index == 0)
              _buildStationResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // FROM
          _buildStationField(
            label: 'FROM',
            icon: Icons.radio_button_checked_rounded,
            iconColor: Colors.greenAccent,
            controller: _fromCtrl,
            focusNode: _fromFocus,
            showSugg: _showFromSugg,
            suggestions: _fromSuggestions,
            onChanged: (v) {
              setState(() {
                _fromSuggestions = _filterStations(v);
                _showFromSugg = true;
              });
            },
            onSelectSugg: (s) {
              setState(() { _fromCtrl.text = s; _showFromSugg = false; });
              _fromFocus.unfocus();
            },
          ),

          // Swap
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: AppTheme.goldAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _swapStations,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.swap_vert_rounded, color: AppTheme.goldAccent, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
              ],
            ),
          ),

          // TO
          _buildStationField(
            label: 'TO',
            icon: Icons.location_on_rounded,
            iconColor: AppTheme.goldAccent,
            controller: _toCtrl,
            focusNode: _toFocus,
            showSugg: _showToSugg,
            suggestions: _toSuggestions,
            onChanged: (v) {
              setState(() {
                _toSuggestions = _filterStations(v);
                _showToSugg = true;
              });
            },
            onSelectSugg: (s) {
              setState(() { _toCtrl.text = s; _showToSugg = false; });
              _toFocus.unfocus();
            },
          ),

          const SizedBox(height: 16),

          // Date picker
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLightNavy.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryLightNavy),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppTheme.goldAccent, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Journey Date', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      Text(
                        DateFormat('EEE, dd MMM yyyy').format(_journeyDate),
                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool showSugg,
    required List<String> suggestions,
    required void Function(String) onChanged,
    required void Function(String) onSelectSugg,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryLightNavy.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryLightNavy),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 15),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Enter station or code...',
                        hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.normal),
                      ),
                      onChanged: onChanged,
                      onTap: () {
                        setState(() {
                          if (label == 'FROM') {
                            _fromSuggestions = _filterStations(controller.text);
                            _showFromSugg = true;
                            _showToSugg   = false;
                          } else {
                            _toSuggestions = _filterStations(controller.text);
                            _showToSugg   = true;
                            _showFromSugg = false;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (controller.text.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() { controller.clear(); }),
                  child: const Icon(Icons.close, color: AppTheme.textMuted, size: 16),
                ),
            ],
          ),
        ),
        if (showSugg && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryDarkNavy,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryLightNavy),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8)],
            ),
            child: Column(
              children: suggestions.map((s) {
                return Listener(
                  onPointerDown: (_) => onSelectSugg(s),
                  child: InkWell(
                    onTap: () {}, // dummy tap callback to preserve ink splash animation
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.train_rounded, color: AppTheme.goldAccent, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s, style: const TextStyle(color: AppTheme.textWhite, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Class filter chips ─────────────────────────────────────────────────────
  Widget _buildClassFilterRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRAVEL CLASS (optional filter)',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kClassNames.entries.map((e) {
            final selected = _selectedClasses.contains(e.key);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedClasses.remove(e.key);
                  } else {
                    _selectedClasses.add(e.key);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.goldAccent : AppTheme.primaryLightNavy.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppTheme.goldAccent : AppTheme.primaryLightNavy,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  e.key,
                  style: TextStyle(
                    color: selected ? AppTheme.primaryNavy : AppTheme.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedClasses.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedClasses.clear()),
              child: const Text(
                'Clear class filter',
                style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, decoration: TextDecoration.underline),
              ),
            ),
          ),
      ],
    );
  }

  // ── Options row: Hide Fares + Quota ───────────────────────────────────────
  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Hide Fares toggle
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _hideFares = !_hideFares),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryLightNavy.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryLightNavy),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _hideFares ? AppTheme.goldAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _hideFares ? AppTheme.goldAccent : AppTheme.textMuted,
                      ),
                    ),
                    child: _hideFares
                        ? const Icon(Icons.check, size: 12, color: AppTheme.primaryNavy)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hide Fares', style: TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Show class only', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Quota dropdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLightNavy.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryLightNavy),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _quota,
                dropdownColor: AppTheme.cardNavy,
                isExpanded: true,
                style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 12),
                items: _quotas.map((q) => DropdownMenuItem(
                  value: q,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Quota', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
                      Text(q, style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )).toList(),
                onChanged: (v) { if (v != null) setState(() => _quota = v); },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Results section ────────────────────────────────────────────────────────
  Widget _buildStationResults() {
    final results = _filteredResults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FOUND ${results.length} TRAINS',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.goldAccent),
            ),
            if (_searchResults.length != results.length)
              Text(
                '(filtered from ${_searchResults.length})',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (results.isEmpty)
          _buildNoResults(isFilterMismatch: _searchResults.isNotEmpty)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            itemBuilder: (context, i) => _buildTrainCard(results[i]),
          ),
      ],
    );
  }

  Widget _buildNoResults({bool isFilterMismatch = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppTheme.cardNavy, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(
            isFilterMismatch ? Icons.filter_alt_off_rounded : Icons.directions_railway_outlined,
            size: 52,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            isFilterMismatch ? 'No Trains Matching Filters' : 'No Trains Found',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            isFilterMismatch
                ? 'We found trains on this route, but none match your selected travel class filters. Try clearing the class filters (tap the active gold classes) to see them.'
                : 'Try different station names or check spelling.\nExample: New Delhi → Varanasi',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (isFilterMismatch)
            TextButton.icon(
              onPressed: () => setState(() => _selectedClasses.clear()),
              icon: const Icon(Icons.clear_all_rounded, size: 14),
              label: const Text('Clear All Class Filters', style: TextStyle(fontSize: 12)),
            )
          else
            TextButton.icon(
              onPressed: () => setState(() {
                _fromCtrl.text = 'New Delhi (NDLS)';
                _toCtrl.text   = 'Varanasi (BSB)';
              }),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Try Example Route', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2 – BY TRAIN NUMBER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTrainNumberTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardNavy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.15)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter Train Number or Name',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLightNavy.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryLightNavy),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: AppTheme.goldAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _trainNumCtrl,
                          style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'e.g. 12302 or Vande Bharat',
                            hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14, letterSpacing: 1),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _performTrainNumSearch(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Examples: 12302 (HWH Rajdhani), Vande Bharat, Shatabdi',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _performTrainNumSearch,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('SEARCH TRAINS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Popular train numbers quick select
          const Text(
            'POPULAR TRAINS',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildPopularTrainsGrid(),

          const SizedBox(height: 24),

          if (_isLoading && _tabController.index == 1)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: AppTheme.goldAccent),
            ))
          else if (_trainNumError != null)
            _buildTrainNumError()
          else if (_trainNumResults.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _trainNumResults.length,
              itemBuilder: (context, i) => _buildTrainCard(_trainNumResults[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularTrainsGrid() {
    final all = _trainService.getAllTrains();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: all.length,
      itemBuilder: (context, i) {
        final t = all[i];
        return GestureDetector(
          onTap: () {
            setState(() {
              _trainNumCtrl.text = t.number;
              _trainNumResults   = [t];
              _trainNumError     = null;
              _hasSearched       = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryLightNavy.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryLightNavy),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${t.number}',
                  style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  t.name.length > 22 ? '${t.name.substring(0, 22)}…' : t.name,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 9),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainNumError() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardNavy, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _trainNumError!,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TRAIN CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTrainCard(Train train) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryLightNavy, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryLightNavy, AppTheme.primaryDarkNavy],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor(train.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _typeColor(train.type), width: 1),
                    ),
                    child: Text(
                      train.type.toUpperCase(),
                      style: TextStyle(color: _typeColor(train.type), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      train.name,
                      style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${train.number}',
                      style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(train.departureTime, style: const TextStyle(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            _stationCode(train.source),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(train.duration, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                const Divider(color: AppTheme.goldAccent, thickness: 1),
                                Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(color: AppTheme.goldAccent, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(train.arrivalTime, style: const TextStyle(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            _stationCode(train.destination),
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Source / Dest full names
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(train.source, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), overflow: TextOverflow.ellipsis)),
                        Expanded(child: Text(train.destination, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RUNNING SCHEDULE',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        _getRunningDaysText(train.type),
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const Divider(color: AppTheme.primaryLightNavy, height: 20),

                  // Class label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('SELECT CLASS', style: TextStyle(color: AppTheme.goldAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      // Track button
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/live_status', arguments: {'trainNumber': train.number, 'trainName': train.name});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location, color: Colors.greenAccent, size: 12),
                              SizedBox(width: 4),
                              Text('TRACK', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Class chips horizontal scroll
                  SizedBox(
                    height: _hideFares ? 46 : 78,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: train.classes.map((cls) => _buildClassChip(train, cls)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassChip(Train train, String cls) {
    final avail    = train.availability[cls] ?? 0;
    final price    = train.prices[cls] ?? 0.0;
    final fullName = kClassNames[cls] ?? cls;

    Color statusColor;
    String statusLabel;
    if (avail > 0) {
      statusColor  = AppTheme.successGreen;
      statusLabel  = 'AVBL $avail';
    } else if (avail == 0) {
      statusColor  = AppTheme.errorRed;
      statusLabel  = 'REGRET';
    } else {
      statusColor  = AppTheme.warningOrange;
      statusLabel  = 'WL${avail.abs()}';
    }

    return GestureDetector(
      onTap: () {
        if (avail > 0) {
          Navigator.pushNamed(
            context,
            '/booking_details',
            arguments: {
              'train': train,
              'travelClass': cls,
              'date': DateFormat('yyyy-MM-dd').format(_journeyDate),
              'price': price,
              'bookedSource': _fromCtrl.text.trim(),
              'bookedDestination': _toCtrl.text.trim(),
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Class $cls is not available ($statusLabel).'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: avail > 0
              ? AppTheme.primaryLightNavy.withOpacity(0.3)
              : AppTheme.errorRed.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: avail > 0 ? AppTheme.primaryLightNavy : AppTheme.errorRed.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(cls, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 13)),
                if (!_hideFares && price > 0)
                  Text('₹${price.toInt()}', style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              fullName.split(' (').first,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
              overflow: TextOverflow.ellipsis,
            ),
            if (!_hideFares) ...[
              const SizedBox(height: 4),
              Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Utils ──────────────────────────────────────────────────────────────────
  String _stationCode(String station) {
    final match = RegExp(r'\((\w+)\)').firstMatch(station);
    return match != null ? match.group(1) ?? station : station;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Vande Bharat': return const Color(0xFF00BCD4);
      case 'Rajdhani':     return const Color(0xFFE91E63);
      case 'Shatabdi':     return const Color(0xFF9C27B0);
      case 'Express':      return const Color(0xFF4CAF50);
      default:             return AppTheme.goldAccent;
    }
  }

  String _getRunningDaysText(String type) {
    if (type == 'Vande Bharat') return 'Mon, Tue, Wed, Fri, Sat, Sun';
    if (type == 'Rajdhani') return 'Mon, Wed, Fri, Sun';
    if (type == 'Shatabdi') return 'Tue, Thu, Sat';
    return 'Runs Daily';
  }
}
