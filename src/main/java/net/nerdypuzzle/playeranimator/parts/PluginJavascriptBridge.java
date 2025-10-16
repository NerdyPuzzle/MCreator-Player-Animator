package net.nerdypuzzle.playeranimator.parts;

import javafx.application.Platform;
import net.mcreator.minecraft.DataListEntry;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.dialogs.DataListSelectorDialog;
import net.mcreator.ui.init.L10N;
import net.mcreator.workspace.Workspace;
import net.nerdypuzzle.playeranimator.Launcher;
import netscape.javascript.JSObject;

import javax.annotation.Nonnull;
import javax.swing.*;
import java.util.List;
import java.util.stream.Collectors;

public class PluginJavascriptBridge {
    private final MCreator mcreator;
    private final Object NESTED_LOOP_KEY = new Object();

    public PluginJavascriptBridge(MCreator mcreator) {
        this.mcreator = mcreator;
    }

    @SuppressWarnings("unused") public void openDataListEntrySelector(JSObject callback) {
        SwingUtilities.invokeLater(() -> {
            String[] retval = new String[] { "", L10N.t("blockly.extension.data_list_selector.no_entry") };
            DataListEntry selected = DataListSelectorDialog.openSelectorDialog(mcreator, PluginJavascriptBridge::getPlayerAnimations,
                    L10N.t("dialog.selector.title"), L10N.t("dialog.selector.player_animation.message"));
            if (selected != null) {
                retval[0] = selected.getName();
                retval[1] = selected.getReadableName();
            }
            Platform.runLater(() -> Platform.exitNestedEventLoop(NESTED_LOOP_KEY, retval));
        });

        String[] retval = (String[]) Platform.enterNestedEventLoop(NESTED_LOOP_KEY);

        callback.call("callback", retval[0], retval[1]);
    }

    private static List<DataListEntry> getPlayerAnimations(@Nonnull Workspace workspace) {
        return Launcher.animations.stream().map(DataListEntry.Dummy::new).collect(Collectors.toList());
    }

}