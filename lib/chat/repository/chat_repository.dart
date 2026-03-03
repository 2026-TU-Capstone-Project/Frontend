import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:capstone_fe/common/model/api_response.dart';
import 'package:capstone_fe/chat/model/chat_model.dart';

part 'chat_repository.g.dart';

@RestApi()
abstract class ChatRepository {
  factory ChatRepository(Dio dio, {String? baseUrl}) = _ChatRepository;

  @POST('/api/v1/chat')
  @Headers({'accessToken': 'true'})
  Future<ApiResponse<ChatResponseData>> sendMessage({
    @Body() required ChatRequestDto body,
  });
}
