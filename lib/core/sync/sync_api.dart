import 'package:dio/dio.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:retrofit/retrofit.dart';

part 'sync_api.g.dart';

/// The server-sync endpoints (ADR-012: Retrofit on the shared Dio).
@RestApi()
abstract class SyncApi {
  factory SyncApi(Dio dio) = _SyncApi;

  @POST('/api/v1/sync/push')
  Future<PushResponseModel> push(@Body() PushRequestModel request);

  @GET('/api/v1/sync/changes')
  Future<ChangesResponseModel> changes(
    @Query('since') int since,
    @Query('limit') int limit,
  );
}
