package net.nerdypuzzle.playeranimator.parts;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import net.mcreator.generator.GeneratorUtils;
import net.mcreator.io.FileIO;
import net.mcreator.io.Transliteration;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.util.ComponentUtils;
import net.mcreator.ui.dialogs.file.FileDialogs;
import net.mcreator.ui.init.L10N;
import net.mcreator.ui.init.UIRES;
import net.mcreator.ui.laf.themes.Theme;
import net.mcreator.ui.workspace.WorkspacePanel;
import net.mcreator.ui.workspace.resources.AbstractResourcePanel;
import net.mcreator.ui.workspace.resources.ResourceFilterModel;
import net.mcreator.util.StringUtils;
import net.nerdypuzzle.playeranimator.Launcher;

import javax.swing.*;
import java.awt.*;
import java.io.File;
import java.io.FileReader;
import java.util.*;
import java.util.List;

public class WorkspacePanelPlayerAnimations extends AbstractResourcePanel<String> {

    public WorkspacePanelPlayerAnimations(WorkspacePanel workspacePanel) {
        super(workspacePanel, new ResourceFilterModel<>(workspacePanel,
                (item, query) -> true, String::valueOf), new Render(), JList.HORIZONTAL_WRAP);

        addToolBarButton("action.workspace.resources.import_player_animation", UIRES.get("16px.importplayeranimation"),
                e -> {
                    File animFile = FileDialogs.getOpenDialog(workspacePanel.getMCreator(), new String[] { ".json" });
                    if (animFile != null) {
                        if (!parseAnimations(animFile).isEmpty()) {
                            FileIO.copyFile(animFile, new File(getAnimationsDir(workspacePanel.getMCreator()),
                                    Transliteration.transliterateString(animFile.getName()).toLowerCase(Locale.ENGLISH).trim()
                                            .replace(":", "").replace(" ", "_")));
                            reloadElements();
                        } else {
                            JOptionPane.showMessageDialog(workspacePanel.getMCreator(), L10N.t("workspace.player_animations.import_error_message", new Object[0]),
                                    L10N.t("workspace.player_animations.import_error"), JOptionPane.ERROR_MESSAGE);
                        }
                    }
                });

        addToolBarButton("common.delete_selected", UIRES.get("16px.delete"), e -> this.deleteCurrentlySelected());
    }

    public List<String> parseAnimations(File animFile) {
        List<String> anims = new ArrayList<>();

        try {
            Gson gson = new Gson();
            FileReader reader = new FileReader(animFile);
            JsonObject root = gson.fromJson(reader, JsonObject.class);
            reader.close();

            if (root.has("animations")) {
                JsonObject animations = root.getAsJsonObject("animations");
                anims.addAll(animations.keySet());
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return anims;
    }

    @Override
    public void deleteCurrentlySelected() {
        List<String> elements = elementList.getSelectedValuesList();
        if (!elements.isEmpty()) {
            int confirm = JOptionPane.showConfirmDialog(this.workspacePanel.getMCreator(), L10N.t("workspace.player_animations.delete_confirm_message", new Object[0]), L10N.t("common.confirmation", new Object[0]), 0, 3, (Icon)null);
            if (confirm == 0) {
                elements.forEach(animation -> {
                    File animFile = new File(getAnimationsDir(workspacePanel.getMCreator()), animation + ".json");
                    if (animFile.exists()) {
                        animFile.delete();
                    }
                });
                reloadElements();
            }
        }
    }

    @Override
    public void reloadElements() {
        filterModel.removeAllElements();

        File animDir = getAnimationsDir(workspacePanel.getMCreator());
        if (animDir.exists() && animDir.isDirectory()) {
            File[] files = animDir.listFiles((dir, name) -> name.endsWith(".json"));
            if (files != null) {
                Launcher.animations.clear();
                for (File file : files) {
                    Launcher.animations.addAll(parseAnimations(file));
                    String fileName = file.getName();
                    String nameWithoutExtension = fileName.substring(0, fileName.lastIndexOf('.'));
                    filterModel.addElement(nameWithoutExtension);
                }
            }
        }
    }

    public File getAnimationsDir(MCreator mcreator) {
        return new File(GeneratorUtils.getSpecificRoot(mcreator.getWorkspace(), mcreator.getWorkspace().getGeneratorConfiguration(), "mod_data_root"), "/bedrock_animations/");
    }

    static class Render extends JLabel implements ListCellRenderer<String> {

        @Override
        public JLabel getListCellRendererComponent(JList<? extends String> list, String ma, int index, boolean isSelected,
                                                   boolean cellHasFocus) {
            setOpaque(isSelected);
            setBackground(isSelected ? Theme.current().getAltBackgroundColor() : Theme.current().getBackgroundColor());
            setText(StringUtils.abbreviateString(ma, 13));
            setToolTipText(ma);
            ComponentUtils.deriveFont(this, 11);
            setVerticalTextPosition(BOTTOM);
            setHorizontalTextPosition(CENTER);
            setHorizontalAlignment(CENTER);
            setIcon(UIRES.get("16px.player_animation"));
            setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));
            return this;
        }

    }
}
