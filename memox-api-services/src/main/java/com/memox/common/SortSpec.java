package com.memox.common;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * One sort entry. {@code TSort} is a feature enum whose constants each map to a whitelisted SQL column in that
 * feature's mapper.
 *
 * @param <TSort> the feature's sort-field enum
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SortSpec<TSort extends Enum<TSort>> {

    @NotNull
    private TSort field;

    @NotNull
    private SortDirection direction = SortDirection.ASC;
}
