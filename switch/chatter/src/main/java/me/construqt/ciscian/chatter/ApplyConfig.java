package me.construqt.ciscian.chatter;

import java.io.StringWriter;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.apache.commons.io.IOUtils;

import me.construqt.ciscian.chatter.Main.CLIOptions;
import me.construqt.ciscian.chatter.connectors.ConnectResult;
import me.construqt.ciscian.chatter.connectors.Connector;
import me.construqt.ciscian.chatter.connectors.ConnectorFactory;

public class ApplyConfig {
	public static void apply(CLIOptions options) throws Exception {
		Connector connector = ConnectorFactory.createConnector(options.connect,
				options.user, options.password);
		ConnectResult connect = connector.connect();

		StringWriter sw = new StringWriter();
		IOUtils.copy(System.in, sw);

		final SwitchChatter sc = SwitchChatter.create(options.flavour,
				connect.getInputStream(), connect.getOutputStream(),
				options.debug, false);

		// setup steps
		sc.enterManagementMode(options.user, options.password);
		sc.disablePaging();
		sc.applyConfig(sw.toString());
		sc.saveRunningConfig();
		sc.exit();

		// start procedure
		Future<List<String>> result = sc.start();

		try {
			List<String> results = result.get(120, TimeUnit.SECONDS);
			int errors = 0;
			for (String line : results) {
				String errorMessage = Util
						.replaceAllTerminalControlCharacters(line);
				if (!errorMessage.isEmpty()) {
					System.err.println(errorMessage);
					errors++;
				}
			}
			if (errors > 0) {
				System.exit(1);
			}
		} catch (Exception e) {
			System.err.println("fatal error occured:");
			e.printStackTrace(System.err);
			System.exit(2);
		} finally {
			sc.close();
			connector.disconnect();
		}
	}

}
