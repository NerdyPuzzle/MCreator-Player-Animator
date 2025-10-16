package net.nerdypuzzle.playeranimator;

import net.mcreator.plugin.JavaPlugin;
import net.mcreator.plugin.Plugin;
import net.mcreator.plugin.events.ui.BlocklyPanelRegisterJSObjects;
import net.mcreator.plugin.events.workspace.MCreatorLoadedEvent;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.init.L10N;
import net.mcreator.ui.variants.modmaker.ModMaker;
import net.nerdypuzzle.playeranimator.parts.PluginJavascriptBridge;
import net.nerdypuzzle.playeranimator.parts.WorkspacePanelPlayerAnimations;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javax.swing.*;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

public class Launcher extends JavaPlugin {

	private static final Logger LOG = LogManager.getLogger("Player Animator");
    public static PluginJavascriptBridge pluginJavascriptBridge = null;
    public static List<String> animations = new ArrayList<>();

	public Launcher(Plugin plugin) {
		super(plugin);

        addListener(BlocklyPanelRegisterJSObjects.class, event -> {
            pluginJavascriptBridge = new PluginJavascriptBridge(event.getBlocklyPanel().getMCreator());
            event.getDOMWindow().put("animbridge", pluginJavascriptBridge);
        });
        addListener(MCreatorLoadedEvent.class, event -> {
            SwingUtilities.invokeLater(() -> {
                MCreator mcreator = event.getMCreator();
                if (mcreator instanceof ModMaker modmaker) {
                    WorkspacePanelPlayerAnimations panel = new WorkspacePanelPlayerAnimations(modmaker.getWorkspacePanel());
                    panel.setOpaque(false);
                    modmaker.getWorkspacePanel().resourcesPan.addResourcesTab(L10N.t("workspacepanel.player_animations", new Object[0]), panel);
                    File animDir = panel.getAnimationsDir(mcreator);
                    if (animDir.exists() && animDir.isDirectory()) {
                        File[] files = animDir.listFiles((dir, name) -> name.endsWith(".json"));
                        if (files != null) {
                            animations.clear();
                            for (File file : files) {
                                animations.addAll(panel.parseAnimations(file));
                            }
                        }
                    }
                }
            });
        });

		LOG.info("Player Animator plugin was loaded");
	}

}