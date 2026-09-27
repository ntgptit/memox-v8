package com.memox.common;

import java.util.List;
import java.util.Objects;

import org.apache.commons.lang3.Validate;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * The shared paged-list response. Build it only through {@link #of(List, PageQuery, long)}, which derives the page
 * counts.
 *
 * @param <T> the item type
 */
@Getter
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public final class PagingResponse<T> {

	private final List<T> items;

	private final int page;

	private final int size;

	private final long totalItems;

	private final int totalPages;

	private final boolean hasNext;

	private final boolean hasPrevious;

	public static <T> PagingResponse<T> of(List<T> items, PageQuery<?> query, long totalItems) {
		Objects.requireNonNull(items, "items");
		Objects.requireNonNull(query, "query");
		Validate.isTrue(totalItems >= 0, "totalItems must not be negative: %d", totalItems);

		int page = query.getPage();
		int size = query.getSize();
		int totalPages = Math.toIntExact((totalItems + size - 1) / size);
		boolean hasNext = page + 1L < totalPages;
		boolean hasPrevious = page > PageQuery.FIRST_PAGE;
		return new PagingResponse<>(List.copyOf(items), page, size, totalItems, totalPages, hasNext, hasPrevious);
	}

}
