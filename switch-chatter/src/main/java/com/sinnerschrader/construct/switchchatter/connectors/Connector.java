package com.sinnerschrader.construct.switchchatter.connectors;

public interface Connector {

	ConnectResult connect() throws Exception;

	void disconnect() throws Exception;
}
