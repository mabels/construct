package me.construqt.ciscian.chatter.steps.generic;

public abstract class Case {

	private String waitFor;

	public Case(String waitFor) {
		this.waitFor = waitFor;
	}

	public abstract Step[] then();

	public boolean match(StringBuffer buffer) {
		return buffer.indexOf(waitFor) >= 0;
	}

}
