package com.memox.common;

import java.util.ArrayList;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import lombok.Getter;
import lombok.Setter;

/**
 * The shared paged-list request. A feature search request extends it with its own filters and its own sort enum, for
 * example {@code DeckSearchRequest extends PageQuery<DeckSortField>}. Pages are zero-based.
 *
 * @param <TSort> the feature's sort-field enum
 */
@Getter
@Setter
public class PageQuery<TSort extends Enum<TSort>> {

	public static final int FIRST_PAGE = 0;

	public static final int MIN_PAGE_SIZE = 1;

	public static final int DEFAULT_PAGE_SIZE = 20;

	public static final int MAX_PAGE_SIZE = 100;

	public static final int MAX_SEARCH_LENGTH = 200;

	@Min(FIRST_PAGE)
	private int page = FIRST_PAGE;

	@Min(MIN_PAGE_SIZE)
	@Max(MAX_PAGE_SIZE)
	private int size = DEFAULT_PAGE_SIZE;

	@Size(max = MAX_SEARCH_LENGTH)
	private String search;

	@Valid
	private List<SortSpec<TSort>> sorts = new ArrayList<>();

	/**
	 * The SQL {@code OFFSET} for this page, as a {@code long} so a huge page number cannot overflow.
	 */
	public long offset() {
		return (long) page * size;
	}

}
