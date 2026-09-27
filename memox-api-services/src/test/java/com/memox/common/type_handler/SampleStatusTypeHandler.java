package com.memox.common.type_handler;

import org.apache.ibatis.type.MappedTypes;

/**
 * Test-only handler; lives in {@code common.type_handler}, so the package scan registers it like a real one.
 */
@MappedTypes(SampleStatus.class)
public class SampleStatusTypeHandler extends BaseEnumTypeHandler<SampleStatus> {

	public SampleStatusTypeHandler() {
		super(SampleStatus.class);
	}

}
