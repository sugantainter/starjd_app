
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';

class CreatorAnalyticsDetailScreen extends StatefulWidget {
  final dynamic accountData;
  const CreatorAnalyticsDetailScreen({super.key, required this.accountData});

  @override
  State<CreatorAnalyticsDetailScreen> createState() => _CreatorAnalyticsDetailScreenState();
}

class _CreatorAnalyticsDetailScreenState extends State<CreatorAnalyticsDetailScreen> {
  int _activeMetricIndex = 3;
  String _activeMetricLabel = 'Views';
  String _activeMetricTabId = 'views';

  final Map<String, List<Map<String, dynamic>>> _platformTabs = {
    'youtube': [
      {'id': 'views', 'name': 'Views', 'index': 3},
      {'id': 'subscribers', 'name': 'Subscribers', 'index': 1},
      {'id': 'likes', 'name': 'Likes', 'index': 4},
    ],
    'facebook': [
      {'id': 'views', 'name': 'Reach', 'index': 3},
      {'id': 'engagement', 'name': 'Engagement', 'index': 1},
    ],
    'linkedin': [
      {'id': 'engagement', 'name': 'Engagement', 'index': 3},
      {'id': 'likes', 'name': 'Likes', 'index': 1},
      {'id': 'comments', 'name': 'Comments', 'index': 2},
    ],
    'instagram': [
      {'id': 'reach', 'name': 'Reach', 'index': 3},
      {'id': 'impressions', 'name': 'Impressions', 'index': 2},
    ],
    'pinterest': [
      {'id': 'impressions', 'name': 'Impressions', 'index': 1},
      {'id': 'saves', 'name': 'Saves', 'index': 2},
      {'id': 'clicks', 'name': 'Clicks', 'index': 3},
    ],
  };

  @override
  void initState() {
    super.initState();
    final platform = widget.accountData['platform']?.toString().toLowerCase() ?? '';
    final tabs = _platformTabs[platform] ?? [{'id': 'views', 'name': 'Views', 'index': 3}];
    _activeMetricTabId = tabs[0]['id'];
    _activeMetricIndex = tabs[0]['index'];
    _activeMetricLabel = tabs[0]['name'];
  }


  @override
  Widget build(BuildContext context) {
    final analytics = widget.accountData['analytics_data'];
    final platform = widget.accountData['platform'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('${platform.toString().toUpperCase()} Performance', 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: analytics == null 
        ? _buildNoDataState(context)
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildMetricGrid(context, analytics),
                const SizedBox(height: 32),
                _buildChartSection(context, analytics),
                const SizedBox(height: 32),
                _buildDemographics(context, analytics),
                const SizedBox(height: 32),
                _buildTopContent(context, analytics),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No analytics data available yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text('Please click refresh or reconnect your account to fetch live metrics.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE63946), Color(0xFFD62828)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFE63946).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              widget.accountData['username']?[0]?.toUpperCase() ?? 'U', 
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.accountData['username'] ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(widget.accountData['profile_url'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, dynamic analytics) {
    // Determine metrics from analytics data
    final followerCount = widget.accountData['followers_count'] ?? 0;
    
    // Attempt to extract total engagement or reach from analytics_data
    int totalEngagement = 0;
    if (analytics['history'] != null && (analytics['history'] as List).isNotEmpty) {
       final lastRow = (analytics['history'] as List).last;
       if (lastRow is List && lastRow.length >= 4) {
          totalEngagement = (lastRow[3] ?? 0).toInt();
       }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(context, 'Followers', followerCount.toString(), Icons.people_outline, Colors.blue),
        _buildMetricCard(context, 'Total Reach', totalEngagement.toString(), Icons.remove_red_eye_outlined, Colors.green),
        _buildMetricCard(context, 'Growth (30d)', '+2.4%', Icons.trending_up, Colors.orange), // Static for now
        _buildMetricCard(context, 'Eng. Rate', '4.2%', Icons.favorite_border, Colors.purple), // Static for now
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, dynamic analytics) {
    final history = analytics['history'] as List?;
    if (history == null || history.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Prepare Data Points
    List<FlSpot> spots = [];
    for (var i = 0; i < history.length; i++) {
        final row = history[i] as List;
        double val = (row.length > _activeMetricIndex ? (row[_activeMetricIndex] ?? 0) : 0).toDouble();
        spots.add(FlSpot(i.toDouble(), val));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Performance History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Metric Switcher Small Tabs
            if (_platformTabs[widget.accountData['platform']?.toString().toLowerCase()] != null)
              Container(
                height: 32,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: (_platformTabs[widget.accountData['platform']?.toString().toLowerCase()]!).map((tab) {
                    final isSelected = _activeMetricTabId == tab['id'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _activeMetricTabId = tab['id'];
                        _activeMetricIndex = tab['index'];
                        _activeMetricLabel = tab['name'];
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSelected && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tab['name'].toString().toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('${_activeMetricLabel.toUpperCase()} Growth (Last 30 Days)', 
          style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFFE63946),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true, 
                    color: const Color(0xFFE63946).withOpacity(0.1)
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemographics(BuildContext context, dynamic analytics) {
    final demos = analytics['demographics'] as List?;
    if (demos == null || demos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Audience Demographics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
           children: [
              _buildGenderSplit(context, demos),
              const SizedBox(width: 20),
              Expanded(child: _buildAgeBrackets(context, demos)),
           ],
        ),
      ],
    );
  }

  Widget _buildGenderSplit(BuildContext context, List demos) {
    double malePercent = 0;
    double femalePercent = 0;
    
    for (var d in demos) {
       if (d[1] == 'male') malePercent += (d[2] ?? 0).toDouble();
       if (d[1] == 'female') femalePercent += (d[2] ?? 0).toDouble();
    }
    
    double total = malePercent + femalePercent;
    if (total > 100) { malePercent = (malePercent/total)*100; femalePercent = (femalePercent/total)*100; }

    return CircularPercentIndicator(
      radius: 60.0,
      lineWidth: 12.0,
      percent: malePercent / 100,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("${malePercent.round()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text("Male", style: TextStyle(fontSize: 10)),
        ],
      ),
      progressColor: Colors.blue,
      backgroundColor: Colors.pink,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }

  Widget _buildAgeBrackets(BuildContext context, List demos) {
    // Map age brackets
    Map<String, double> brackets = {};
    for (var d in demos) {
       String age = d[0].toString().replaceAll('age', '');
       brackets[age] = (brackets[age] ?? 0) + (d[2] ?? 0).toDouble();
    }

    return Column(
       children: brackets.entries.map((e) => Padding(
         padding: const EdgeInsets.only(bottom: 8),
         child: LinearPercentIndicator(
           lineHeight: 8.0,
           percent: (e.value / 100).clamp(0, 1),
           leading: SizedBox(width: 45, child: Text(e.key, style: const TextStyle(fontSize: 11))),
           progressColor: const Color(0xFFE63946),
           backgroundColor: Colors.grey.withOpacity(0.2),
           barRadius: const Radius.circular(4),
         ),
       )).toList().take(4).toList(),
    );
  }

  Widget _buildTopContent(BuildContext context, dynamic analytics) {
    final contents = (analytics['top_videos'] ?? analytics['top_posts']) as List?;
    if (contents == null || contents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Performing Content', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...contents.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  image: item['thumbnail'] != null ? DecorationImage(image: NetworkImage(item['thumbnail']), fit: BoxFit.cover) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? 'Post Title', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${item['views']} Impressions', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        )).toList().take(5).toList(),
      ],
    );
  }
}
