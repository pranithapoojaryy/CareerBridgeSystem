import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/identity_helper.dart';
import '../../../../features/shared/presentation/widgets/org_identity_tile.dart';
import '../../data/network_repository.dart';
import 'chat_screen.dart';
import 'network_profile_view.dart';
import 'recruiter_profile_view.dart';
import '../../../college/presentation/profile/college_public_profile_screen.dart';

class NetworkScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const NetworkScreen({super.key, this.onBackPressed});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _repository = NetworkRepository();
  final _searchController = TextEditingController();

  // State
  bool _isLoading = true;
  List<Map<String, dynamic>> _myConversations = [];
  List<Map<String, dynamic>> _myConnections = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _suggestedConnections = [];
  List<Map<String, dynamic>> _discoverProfiles = []; // All browsable profiles
  bool _isLoadingDiscover = false;

  // Search State
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';
  String _selectedRole =
      'all'; // 'all', 'student', 'recruiter', 'college_admin'

  // Desktop Split View State
  String? _activeChatUserId;
  Map<String, dynamic>? _activeChatUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      var conversations = await _repository.getMyConversations();
      var connections = await _repository.getMyConnections();
      var requests = await _repository.getPendingRequests();
      var bio = await _repository.getSuggestedConnections();

      // Enhance with organizational identity logic (Recruiters & Colleges)
      conversations = await IdentityHelper.enhanceUserList(conversations);
      connections = await IdentityHelper.enhanceUserList(connections);
      requests = await IdentityHelper.enhanceUserList(requests);
      bio = await IdentityHelper.enhanceUserList(bio);

      if (mounted) {
        setState(() {
          _myConversations = conversations;
          _myConnections = connections;
          _pendingRequests = requests;
          _suggestedConnections = bio;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    // Always load discover profiles (independent of connections)
    _loadDiscoverProfiles();
  }

  Future<void> _loadDiscoverProfiles() async {
    if (!mounted) return;
    setState(() => _isLoadingDiscover = true);
    try {
      final roleFilter = _selectedRole == 'college_admin' ? 'college' : _selectedRole;
      var profiles = await _repository.browseProfiles(roleFilter: roleFilter, limit: 50);
      profiles = await IdentityHelper.enhanceUserList(profiles);
      if (mounted) {
        setState(() {
          _discoverProfiles = profiles;
          _isLoadingDiscover = false;
        });
      }
    } catch (e) {
      debugPrint('_loadDiscoverProfiles error: $e');
      if (mounted) setState(() => _isLoadingDiscover = false);
    }
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    debugPrint('🔍 _handleSearch called with query: $query');
    setState(() {
      _isSearching = true;
      _searchError = '';
      _searchResults = [];
    });
    debugPrint('🔍 State set: isSearching=true, searchResults cleared');

    try {
      var results = await _repository.searchUsers(query);
      debugPrint('🔍 Got ${results.length} results from repository');
      results = await IdentityHelper.enhanceUserList(results);
      debugPrint('🔍 Enhanced results: ${results.length} items');

      if (mounted) {
        debugPrint('🔍 Setting state with ${results.length} search results');
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        debugPrint(
          '🔍 State updated: searchResults=${_searchResults.length}, isSearching=false',
        );
      }
    } catch (e) {
      debugPrint('🔍 Error in _handleSearch: $e');
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _handleConnectFromSearch(String targetUserId) async {
    try {
      await _repository.sendConnectionRequest(targetUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent!')),
        );
        _handleSearch(); // Refresh search status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleRequest(String connectionId, bool accept) async {
    try {
      if (accept) {
        await _repository.acceptConnectionRequest(connectionId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connection accepted!')));
      } else {
        await _repository.ignoreConnectionRequest(connectionId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request ignored.')));
      }
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildSplitLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black87,
          ),
          onPressed: () {
            if (widget.onBackPressed != null) {
              widget.onBackPressed!();
            } else {
              Navigator.maybePop(context);
            }
          },
        ),
        title: Text(
          'My Network',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Connections'),
            Tab(text: 'Messages'),
            Tab(text: 'Requests'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_tabController.index != 2) // Don't show filters on Requests tab
            _buildFilterChips(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildConnectionsList(isMobile: true),
                _buildConversationsList(isMobile: true),
                _buildRequestsList(),
                // Add search bar for mobile layout
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search people...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                        ),
                        onSubmitted: (_) => _handleSearch(),
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                    Expanded(child: _buildSearchTab()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT PANEL: Connections & Search (Flex 2)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () {
                            if (widget.onBackPressed != null) {
                              widget.onBackPressed!();
                            } else {
                              Navigator.maybePop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'My Network',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search people...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                    const SizedBox(height: 16),
                    _buildFilterChips(isDesktop: true),
                  ],
                ),
              ),
              Expanded(
                child: _isSearching || _searchResults.isNotEmpty
                    ? _buildSearchTab()
                    : _buildConnectionsGrid(),
              ),
            ],
          ),
        ),

        // RIGHT PANEL: Messages & Requests (Flex 1)
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              // Connection Requests Section (Always Visible)
              Container(
                height: _pendingRequests.isEmpty ? 60 : 250, // Compact if empty
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: _pendingRequests.isEmpty
                    ? Center(
                        child: Text(
                          'No New Connection Requests',
                          style: GoogleFonts.outfit(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Connection Requests',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: Text(
                                    _pendingRequests.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: _buildRequestsList()),
                        ],
                      ),
              ),
              Expanded(
                child: _activeChatUserId != null
                    ? _buildInlineChatWindow()
                    : _buildConversationsList(isMobile: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Sub-Widgets ---

  Widget _buildFilterChips({bool isDesktop = false}) {
    final roles = [
      {'id': 'all', 'label': 'All'},
      {'id': 'student', 'label': 'Students'},
      {'id': 'recruiter', 'label': 'Recruiters'},
      {'id': 'college_admin', 'label': 'Colleges'},
    ];

    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final role = roles[index];
          final isSelected = _selectedRole == role['id'];
          return ChoiceChip(
            label: Text(
              role['label']!,
              style: GoogleFonts.outfit(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedRole = role['id']!);
                _loadDiscoverProfiles(); // Reload discover on filter change
              }
            },
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredList(List<Map<String, dynamic>> list) {
    if (_selectedRole == 'all') return list;
    if (_selectedRole == 'college_admin') {
      return list.where((u) => u['role'] == 'college' || u['role'] == 'college_admin').toList();
    }
    return list.where((user) => user['role'] == _selectedRole).toList();
  }

  Widget _buildConnectionsGrid() {
    final filtered = _getFilteredList(_myConnections);
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // My Connections section (if any)
          if (filtered.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Your Connections (${filtered.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildConnectionCard(filtered[index]),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],

          // Discover People section (always shown)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    filtered.isEmpty ? 'Discover People' : 'People You May Know',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingDiscover)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: _discoverProfiles.isEmpty && !_isLoadingDiscover
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No profiles found. Try a different filter.',
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = _discoverProfiles[index];
                        return _buildDiscoverCard(user);
                      },
                      childCount: _discoverProfiles.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverCard(Map<String, dynamic> user) {
    final identity = IdentityHelper.getOrganizationalIdentity(user);
    final name = identity['display_name'] ?? 'Unknown';
    final avatar = identity['avatar_url'];
    final role = identity['role_label'] ?? 'Member';
    final status = user['connection_status'] as String? ?? 'none';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => _openProfile(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: avatar == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                role,
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: status == 'connected'
                    ? OutlinedButton(
                        onPressed: () => _openProfile(user),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          side: const BorderSide(color: Colors.green),
                        ),
                        child: Text(
                          'Connected',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : status == 'pending'
                    ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: Text(
                          'Pending',
                          style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          await _handleConnectFromSearch(
                            user['user_id'] as String? ?? user['id'] as String,
                          );
                          _loadDiscoverProfiles();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 0,
                        ),
                        child: Text(
                          'Connect',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedConnects() {
    if (_suggestedConnections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'People you may know',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: View all suggestions
              },
              child: Text(
                'See all',
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedConnections.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final user = _suggestedConnections[index];
              return _buildSuggestionCard(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> user) {
    final identity = IdentityHelper.getOrganizationalIdentity(user);
    final name = identity['display_name'] ?? 'Unknown';
    final avatar = identity['avatar_url'];
    final role = identity['role_label'] ?? 'Member';
    final mutuals = user['mutual_count'] ?? 0;

    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openProfile(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? Text(name[0], style: const TextStyle(fontSize: 20))
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  role,
                  style: GoogleFonts.outfit(color: Colors.grey, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (mutuals > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '$mutuals mutual connections',
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        _handleConnectFromSearch(user['user_id'] ?? user['id']),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(
                      'Connect',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionsList({required bool isMobile}) {
    final filtered = _getFilteredList(_myConnections);
    // Build a combined list: existing connections + discover profiles
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Existing connections
          if (filtered.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'My Connections (${filtered.length})',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildConnectionCard(filtered[index], isList: true),
                ),
                childCount: filtered.length,
              ),
            ),
          ],

          // Discover section
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    filtered.isEmpty ? 'Discover People' : 'People You May Know',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoadingDiscover)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
          if (_discoverProfiles.isEmpty && !_isLoadingDiscover)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No profiles found for this filter.',
                    style: GoogleFonts.outfit(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildDiscoverCard(_discoverProfiles[index]),
                  childCount: _discoverProfiles.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    Map<String, dynamic> user, {
    bool isList = false,
  }) {
    final identity = IdentityHelper.getOrganizationalIdentity(user);
    final name = identity['display_name'] ?? 'Unknown Member';
    final avatar = identity['avatar_url'];
    final role = identity['role_label'] ?? 'Member';

    if (isList) {
      return ListTile(
        leading: CircleAvatar(
          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
          child: avatar == null ? Text(name[0]) : null,
        ),
        title: Text(
          name,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(role),
        trailing: IconButton(
          icon: const Icon(Icons.message_outlined),
          onPressed: () => _openChat(user),
        ),
        onTap: () => _openProfile(user),
      );
    }

    return InkWell(
      onTap: () => _openProfile(user),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: avatar != null ? NetworkImage(avatar) : null,
              child: avatar == null
                  ? Text(name[0], style: const TextStyle(fontSize: 24))
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              role,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _openChat(user),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
              child: const Text('Message'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList({required bool isMobile}) {
    if (_myConversations.isEmpty)
      return _buildEmptyState(
        'No messages',
        'Start a chat!',
        Icons.chat_bubble_outline,
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: Builder(
              builder: (context) {
                final filtered = _getFilteredList(_myConversations);
                if (filtered.isEmpty) {
                  return _buildEmptyState(
                    _selectedRole == 'all'
                        ? 'No messages'
                        : 'No ${_selectedRole}s found',
                    'Start a chat!',
                    Icons.chat_bubble_outline,
                  );
                }
                return ListView.separated(
                  padding: isMobile
                      ? const EdgeInsets.all(16)
                      : EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final conversation = filtered[index];
                    final identity = IdentityHelper.getOrganizationalIdentity(
                      conversation,
                    );
                    final name = identity['display_name'] ?? 'Unknown';
                    final avatar = identity['avatar_url'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: avatar != null
                            ? NetworkImage(avatar)
                            : null,
                        child: avatar == null ? Text(name[0]) : null,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Click to chat...',
                        style: GoogleFonts.outfit(fontSize: 12),
                      ),
                      onTap: () {
                        if (isMobile) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                targetUserId:
                                    conversation['user_id'] ??
                                    conversation['id'],
                                targetUserName: name,
                                targetUserAvatar: avatar,
                              ),
                            ),
                          );
                        } else {
                          _openChat(conversation);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    if (_pendingRequests.isEmpty)
      return _buildEmptyState(
        'No requests',
        'No new connection requests.',
        Icons.mail_outline,
      );

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          final identity = IdentityHelper.getOrganizationalIdentity(request);
          final name = identity['display_name'] ?? 'Unknown User';
          final avatar = identity['avatar_url'];
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null ? Text(name[0]) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        identity['role_label'] ?? 'Student',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () =>
                      _handleRequest(request['connection_id'], true),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () =>
                      _handleRequest(request['connection_id'], false),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchTab() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchError.isNotEmpty) {
      return Center(
        child: Text(_searchError, style: const TextStyle(color: Colors.red)),
      );
    }
    final filtered = _getFilteredList(_searchResults);
    return filtered.isEmpty
        ? _buildEmptyState(
            'No results',
            _selectedRole == 'all'
                ? 'Try searching for someone else.'
                : 'No ${_selectedRole}s found for this search.',
            Icons.search_off,
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = filtered[index];
              return _buildSearchResultCard(user);
            },
          );
  }

  Widget _buildSearchResultCard(Map<String, dynamic> user) {
    final status = user['connection_status'] ?? 'none';

    return OrgIdentityTile(
      userData: user,
      onTap: () => _openProfile(user),
      trailing: status == 'connected'
          ? const Icon(Icons.check_circle, color: Colors.green)
          : status == 'pending'
          ? const Text('Pending', style: TextStyle(color: Colors.grey))
          : ElevatedButton(
              onPressed: () =>
                  _handleConnectFromSearch(user['user_id'] ?? user['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Connect'),
            ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Text(subtitle, style: GoogleFonts.outfit(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildInlineChatWindow() {
    final identity = _activeChatUser != null
        ? IdentityHelper.getOrganizationalIdentity(_activeChatUser!)
        : null;
    final String displayName = identity?['display_name'] ?? 'Chat';
    final String? displayAvatar = identity?['avatar_url'];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _activeChatUserId = null),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundImage: displayAvatar != null
                    ? NetworkImage(displayAvatar)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ChatScreen(
            targetUserId: _activeChatUserId!,
            targetUserName: displayName,
            targetUserAvatar: displayAvatar,
          ),
        ),
      ],
    );
  }

  void _openChat(Map<String, dynamic> user) {
    final identity = IdentityHelper.getOrganizationalIdentity(user);
    final String displayName = identity['display_name'] ?? 'User';
    final String? displayAvatar = identity['avatar_url'];

    if (MediaQuery.of(context).size.width > 900) {
      if (mounted) {
        setState(() {
          _activeChatUserId = user['user_id'] ?? user['id'];
          _activeChatUser = user;
        });
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            targetUserId: user['user_id'] ?? user['id'],
            targetUserName: displayName,
            targetUserAvatar: displayAvatar,
          ),
        ),
      );
    }
  }

  void _openProfile(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 900 ? 0 : 16,
          vertical: MediaQuery.of(context).size.width > 900 ? 0 : 24,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width > 900
              ? 1400
              : double.infinity,
          height: MediaQuery.of(context).size.height > 900
              ? 850
              : MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildProfileView(user),
        ),
      ),
    );
  }

  Widget _buildProfileView(Map<String, dynamic> user) {
    final role = user['role'];
    if (role == 'recruiter') {
      return RecruiterProfileView(
        userId: user['user_id'] ?? user['id'],
        userName: user['full_name'] ?? 'User',
        userAvatar: user['avatar_url'],
      );
    } else if (role == 'college' || role == 'college_admin') {
      return CollegePublicProfileScreen(
        userId: user['user_id'] ?? user['id'],
        userName: user['full_name'] ?? 'College',
        userAvatar: user['avatar_url'],
      );
    } else {
      return NetworkProfileView(
        userId: user['user_id'] ?? user['id'],
        userName: user['full_name'] ?? 'User',
        userAvatar: user['avatar_url'],
        userRole: role ?? 'student',
      );
    }
  }
}
