import 'package:flutter/services.dart';
import 'package:memox/features/topik/data/datasources/topik_content_asset_data_source.dart';
import 'package:memox/features/topik/data/repositories/topik_content_repository_impl.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_content_repository_provider.g.dart';

/// The bundled TOPIK content, parsed once per app run (spec §13.4, owner
/// approval 2026-10-15): kept alive because the content never changes while
/// the app runs.
@Riverpod(keepAlive: true)
TopikContentRepository topikContentRepository(Ref ref) =>
    TopikContentRepositoryImpl(
      load: TopikContentAssetDataSource(
        rootBundle,
        assetPaths: () async =>
            (await AssetManifest.loadFromAssetBundle(rootBundle))
                .listAssets()
                .toSet(),
      ).load,
    );
