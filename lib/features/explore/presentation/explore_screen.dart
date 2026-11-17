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
  String query = '';
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        const FeatureDestinationHeader(title: 'Explore', subtitle: ''),
        Expanded(
          child: SingleChildScrollView(
            key: const PageStorageKey('explore-discovery-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Search nearby',
                    hintText: 'Places, music, coffee…',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: filter == null,
                        onSelected: (_) => setState(() => filter = null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Places'),
                        selected: filter == DiscoveryItemType.place,
                        onSelected: (_) =>
                            setState(() => filter = DiscoveryItemType.place),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Activities'),
                        selected: filter == DiscoveryItemType.activity,
                        onSelected: (_) =>
                            setState(() => filter = DiscoveryItemType.activity),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  filter == DiscoveryItemType.place
                      ? 'Places within 2.5 km of your location. Browsing does not activate presence.'
                      : 'Browsing does not activate presence. Add activities to record your plans, not attendance.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                HomeDiscovery(
                  interests: ref.watch(homeDiscoveryInterestsProvider),
                  filter: filter,
                  query: query,
                  vertical: true,
                  showSeeAll: filter != DiscoveryItemType.place,
                  onEventSelected: (id) =>
                      context.push(AppRoutes.eventDetails(id)),
                  onSeeAll: () => context.push(AppRoutes.exploreActivities),
                  seeAllLabel: 'See activities',
                ),
                const SizedBox(height: 20),
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
