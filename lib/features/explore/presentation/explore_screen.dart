import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../discovery/domain/discovery_item.dart';
import '../../home/presentation/home_screen.dart'
    show homeDiscoveryInterestsProvider;
import '../../home/presentation/widgets/home_discovery.dart';
import '../../navigation/presentation/feature_destination_header.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  DiscoveryItemType? filter;
  String placeQuery = '';
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        const FeatureDestinationHeader(
          title: 'Explore',
          subtitle: 'Find places and activities worth stepping out for.',
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const PageStorageKey('explore-discovery-scroll'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: filter == null,
                      onSelected: (_) => setState(() => filter = null),
                    ),
                    ChoiceChip(
                      label: const Text('Places'),
                      selected: filter == DiscoveryItemType.place,
                      onSelected: (_) =>
                          setState(() => filter = DiscoveryItemType.place),
                    ),
                    ChoiceChip(
                      label: const Text('Activities'),
                      selected: filter == DiscoveryItemType.activity,
                      onSelected: (_) =>
                          setState(() => filter = DiscoveryItemType.activity),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  filter == DiscoveryItemType.place
                      ? 'Places within 2.5 km of your location. Browsing does not activate presence.'
                      : 'Browsing does not activate presence. Add activities to record your plans, not attendance.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                if (filter == DiscoveryItemType.place) ...[
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter nearby places',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => placeQuery = value),
                  ),
                  const SizedBox(height: 16),
                ],
                HomeDiscovery(
                  interests: ref.watch(homeDiscoveryInterestsProvider),
                  filter: filter,
                  searchQuery: filter == DiscoveryItemType.place
                      ? placeQuery
                      : '',
                  showSeeAll: filter != DiscoveryItemType.place,
                  onSeeAll: () => context.push(AppRoutes.exploreActivities),
                  seeAllLabel: 'See activities',
                ),
                const SizedBox(height: 24),
                if (filter != DiscoveryItemType.place)
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.exploreActivities),
                    icon: const Icon(Icons.search),
                    label: const Text('Search all activities'),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
