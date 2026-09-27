package com.memox.common;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import org.junit.jupiter.api.Test;

class PagingResponseTest {

    private enum TestSort {
        NAME
    }

    @Test
    void firstPageHasNextButNoPrevious() {
        PagingResponse<String> response = PagingResponse.of(List.of("a", "b"), query(0, 20), 45);

        assertThat(response.getItems()).containsExactly("a", "b");
        assertThat(response.getPage()).isZero();
        assertThat(response.getSize()).isEqualTo(20);
        assertThat(response.getTotalItems()).isEqualTo(45);
        assertThat(response.getTotalPages()).isEqualTo(3);
        assertThat(response.isHasNext()).isTrue();
        assertThat(response.isHasPrevious()).isFalse();
    }

    @Test
    void middlePageHasBothNeighbours() {
        PagingResponse<String> response = PagingResponse.of(List.of("x"), query(1, 20), 45);

        assertThat(response.isHasNext()).isTrue();
        assertThat(response.isHasPrevious()).isTrue();
    }

    @Test
    void lastPageHasNoNext() {
        PagingResponse<String> response = PagingResponse.of(List.of("x"), query(2, 20), 45);

        assertThat(response.isHasNext()).isFalse();
        assertThat(response.isHasPrevious()).isTrue();
    }

    @Test
    void exactMultipleHasNoExtraPage() {
        PagingResponse<String> response = PagingResponse.of(List.of("x"), query(1, 20), 40);

        assertThat(response.getTotalPages()).isEqualTo(2);
        assertThat(response.isHasNext()).isFalse();
    }

    @Test
    void emptyResultHasNoPages() {
        PagingResponse<String> response = PagingResponse.of(List.of(), query(0, 20), 0);

        assertThat(response.getItems()).isEmpty();
        assertThat(response.getTotalPages()).isZero();
        assertThat(response.isHasNext()).isFalse();
        assertThat(response.isHasPrevious()).isFalse();
    }

    @Test
    void pagePastTheEndIsEmptyAndPointsBack() {
        PagingResponse<String> response = PagingResponse.of(List.of(), query(5, 20), 45);

        assertThat(response.getItems()).isEmpty();
        assertThat(response.getTotalPages()).isEqualTo(3);
        assertThat(response.isHasNext()).isFalse();
        assertThat(response.isHasPrevious()).isTrue();
    }

    @Test
    void negativeTotalIsRejected() {
        assertThatThrownBy(() -> PagingResponse.of(List.of(), query(0, 20), -1))
                .isInstanceOf(IllegalArgumentException.class);
    }

    private PageQuery<TestSort> query(int page, int size) {
        PageQuery<TestSort> query = new PageQuery<>();
        query.setPage(page);
        query.setSize(size);
        return query;
    }
}
