package io.bitpet.notification;

import io.bitpet.auth.dto.SignupRequest;
import io.bitpet.auth.service.AuthService;
import io.bitpet.common.exception.BusinessException;
import io.bitpet.community.dto.CommentCreateRequest;
import io.bitpet.community.dto.PostCreateRequest;
import io.bitpet.community.service.PostService;
import io.bitpet.notification.domain.NotificationStatus;
import io.bitpet.notification.domain.NotificationType;
import io.bitpet.notification.dto.NotificationLogResponse;
import io.bitpet.notification.service.NotificationService;
import io.bitpet.support.IntegrationTestBase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * 알림함 — 바로가기용 postId, 모두 읽음, 하나·전체 삭제 (2026-11-02).
 */
class NotificationInboxIntegrationTest extends IntegrationTestBase {

    private static final AtomicInteger SEQ = new AtomicInteger();
    private static final long FREE_BOARD = 1L;

    @Autowired private NotificationService notificationService;
    @Autowired private PostService postService;
    @Autowired private AuthService authService;

    @Test
    void community_notifications_carry_post_id_for_shortcut() {
        Long writer = signup();
        Long reader = signup();
        Long postId = postService.createPost(writer,
                new PostCreateRequest(FREE_BOARD, "제목", "본문")).id();

        postService.createComment(reader, postId, new CommentCreateRequest(null, "댓글"));
        postService.toggleLike(reader, postId);

        List<NotificationLogResponse> list = notificationService.listNotifications(writer);
        // 댓글 알림의 referenceId 는 comment_id 지만 postId 는 글을 가리켜야 한다
        assertThat(list).extracting(NotificationLogResponse::notificationType)
                .contains(NotificationType.COMMUNITY_COMMENT, NotificationType.COMMUNITY_LIKE);
        assertThat(list).allSatisfy(n -> assertThat(n.postId()).isEqualTo(postId));
    }

    @Test
    void mark_all_read_and_delete() {
        Long me = signup();
        Long other = signup();
        notificationService.createSystemNotification(me, "공지1", "본문");
        notificationService.createSystemNotification(me, "공지2", "본문");
        notificationService.createSystemNotification(me, "공지3", "본문");
        notificationService.createSystemNotification(other, "남의 공지", "본문");

        notificationService.markAllRead(me);
        assertThat(notificationService.listNotifications(me))
                .allSatisfy(n -> assertThat(n.status()).isEqualTo(NotificationStatus.READ));
        // 남의 알림은 그대로
        assertThat(notificationService.listNotifications(other).get(0).status())
                .isNotEqualTo(NotificationStatus.READ);

        Long first = notificationService.listNotifications(me).get(0).id();
        // 남의 알림은 못 지운다
        assertThatThrownBy(() -> notificationService.delete(other, first))
                .isInstanceOf(BusinessException.class);
        notificationService.delete(me, first);
        assertThat(notificationService.listNotifications(me)).hasSize(2)
                .extracting(NotificationLogResponse::id).doesNotContain(first);

        notificationService.deleteAll(me);
        assertThat(notificationService.listNotifications(me)).isEmpty();
        assertThat(notificationService.listNotifications(other)).hasSize(1);
    }

    // -------------------------------------------------------------------------

    private Long signup() {
        int n = SEQ.incrementAndGet();
        return authService.signup(new SignupRequest(
                "inbox" + n + "@example.com", "Passw0rd!23", "inboxuser" + n, null,
                true, true, true, false)).id();
    }
}
