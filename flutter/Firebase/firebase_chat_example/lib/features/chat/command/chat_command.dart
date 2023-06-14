import 'dart:async';

import 'package:firebase_chat_example/features/chat/domain/message_entity.dart';
import 'package:firebase_chat_example/features/chat/repo/update_chat_room.dart';
import 'package:firebase_chat_example/features/user/repo/refs/auth_refs.dart';
import 'package:firebase_chat_example/features/user/repo/refs/user_refs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_room_entity.dart';
import '../repo/create_chat_room.dart';
import '../repo/send_message.dart';

final chatAsyncNotifierCommand = AsyncNotifierProvider<ChatCommand, void>(() {
  return ChatCommand();
});

class ChatCommand extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // commandなので必ずvoid型でなければならない。
  }

  Future<void> sendEvent({
    required String content,
    required String receiverUserId,
    required int? messageCount,
  }) async {
    final currentUid = authRef.currentUser!.uid;
    final receiverUser = await userDocRef(userId: receiverUserId).get();
    final senderUser = await userDocRef(userId: currentUid).get();

    // messageCountがnullのとき0を代入、他は何もしない。
    messageCount ??= 0;

    //相手の
    final receiverChatRoom = ChatRoomEntity(
      chatRoomId: currentUid,
      chatUserName: senderUser.data()!.name,
      lastMessage: content,
      messageCount: messageCount + 1,
    );
    //自分の
    final senderChatRoom = ChatRoomEntity(
      chatRoomId: receiverUserId,
      chatUserName: receiverUser.data()!.name,
      lastMessage: content,
      messageCount: 0,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await createChatRoom(
        receiverChatRoom: receiverChatRoom,
        receiverUserId: receiverUserId,
        senderChatRoom: senderChatRoom,
        senderUserId: currentUid,
      );
    });
    final message = MessageEntity(
      content: content,
      receiverId: receiverUserId,
      senderId: currentUid,
    );
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        return await sendMessage(
          message: message,
          receiverUserId: receiverUserId,
          senderUserId: currentUid,
        );
      },
    );
    if (!state.isLoading && !state.hasError) {
      print('🐯 メッセージ送信 !!!');
    }
  }

  Future<void> markAsReadEvent({
    required String receiverUserId,
  }) async {
    final currentUid = authRef.currentUser!.uid;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await updateChatRoom(
        currentUserUserId: currentUid,
        receiverUserId: receiverUserId,
      );
    });
  }
}
