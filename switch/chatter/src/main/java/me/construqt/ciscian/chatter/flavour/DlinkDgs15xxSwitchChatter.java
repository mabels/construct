package me.construqt.ciscian.chatter.flavour;

import me.construqt.ciscian.chatter.steps.flavoured.AnswerYes;
import me.construqt.ciscian.chatter.steps.flavoured.CiscoCopy;
import me.construqt.ciscian.chatter.steps.flavoured.Enable;
import me.construqt.ciscian.chatter.steps.flavoured.EnterInput;
import me.construqt.ciscian.chatter.steps.flavoured.Exit;
import me.construqt.ciscian.chatter.steps.flavoured.PasswordPrompt;
import me.construqt.ciscian.chatter.steps.flavoured.ShowRunningConfig;
import me.construqt.ciscian.chatter.steps.generic.Case;
import me.construqt.ciscian.chatter.steps.generic.CollectOutputStep;
import me.construqt.ciscian.chatter.steps.generic.Step;
import me.construqt.ciscian.chatter.steps.generic.SwitchStep;
import me.construqt.ciscian.chatter.steps.generic.WaitForStep;

public class DlinkDgs15xxSwitchChatter extends GenericCiscoFlavourSwitchChatter {

	@Override
	protected void enterManagementMode(final String user,final  String password) {
		getOutputConsumer().addStep(new SwitchStep( //
				new Case(">") {
					public Step[] then() {
						return new Step[] {};
					}
				}, new Case("Password:") {
					public Step[] then() {
						return new Step[] { new EnterInput(password) };
					}
				}));

		super.enterManagementMode(user, password);
	}

	public void retrieveConfig() {
		getOutputConsumer().addStep(new ShowRunningConfig());
		getOutputConsumer().addStep(new WaitForStep("Current configuration :"));
		getOutputConsumer().addStep(new WaitForStep("\n\r"));
		getOutputConsumer().addStep(new WaitForStep("\n\r"));
		getOutputConsumer().addStep(
				new CollectOutputStep(false, "End of configuration file", "#",
						"\n\r", "\n\r"));
	}

	public void exit() {
		getOutputConsumer().addStep(new Exit());
	}

	@Override
	protected void saveRunningConfig() {
		getOutputConsumer().addStep(new CiscoCopy());
		getOutputConsumer().addStep(new AnswerYes());
	}

}
