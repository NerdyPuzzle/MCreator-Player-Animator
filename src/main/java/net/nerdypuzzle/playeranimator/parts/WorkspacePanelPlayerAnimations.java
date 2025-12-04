package net.nerdypuzzle.playeranimator.parts;

import com.google.gson.*;
import javafx.animation.AnimationTimer;
import javafx.application.Platform;
import javafx.embed.swing.JFXPanel;
import javafx.embed.swing.SwingFXUtils;
import javafx.scene.Group;
import javafx.scene.control.ListCell;
import javafx.scene.image.Image;
import javafx.scene.image.PixelReader;
import javafx.scene.image.PixelWriter;
import javafx.scene.image.WritableImage;
import javafx.scene.shape.MeshView;
import javafx.scene.shape.TriangleMesh;
import javafx.scene.PerspectiveCamera;
import javafx.scene.Scene;
import javafx.scene.SceneAntialiasing;
import javafx.scene.paint.Color;
import javafx.scene.paint.PhongMaterial;
import javafx.scene.transform.Rotate;
import javafx.scene.transform.Scale;
import javafx.scene.transform.Translate;
import net.mcreator.generator.GeneratorUtils;
import net.mcreator.io.FileIO;
import net.mcreator.io.Transliteration;
import net.mcreator.ui.MCreator;
import net.mcreator.ui.component.util.PanelUtils;
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
import javax.swing.border.AbstractBorder;
import javax.swing.border.Border;
import javax.swing.border.EmptyBorder;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileReader;
import java.util.*;
import java.util.List;

public class WorkspacePanelPlayerAnimations extends AbstractResourcePanel<String> {
    private AnimationManager animationManager;
    private JFXPanel previewPanel;
    private AnimationControlPanel controlPanel;

    public WorkspacePanelPlayerAnimations(WorkspacePanel workspacePanel) {
        super(workspacePanel, new ResourceFilterModel<>(workspacePanel,
                (item, query) -> true, String::valueOf), new Render(), JList.VERTICAL);

        removeAll();
        setLayout(new BorderLayout());

        add(bar, BorderLayout.NORTH);

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

        JSplitPane mainSplitPane = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT);
        mainSplitPane.setResizeWeight(0.2);
        mainSplitPane.setBackground(Theme.current().getAltBackgroundColor());

        JScrollPane listScrollPane = new JScrollPane(elementList);
        listScrollPane.setMinimumSize(new Dimension(200, 0));
        listScrollPane.getViewport().setBackground(Theme.current().getSecondAltBackgroundColor());

        class ListRenderer extends JPanel implements ListCellRenderer<String> {
            private final JLabel nameLabel = new JLabel();
            private final Border topSeparatorBorder = new InsetTopLineBorder(Theme.current().getAltForegroundColor(), 10, 5, 4);
            private final Border emptyBorder = BorderFactory.createEmptyBorder(1, 0, 0, 0);

            ListRenderer() {
                setBackground(Theme.current().getSecondAltBackgroundColor());
                nameLabel.setFont(getFont().deriveFont(20.0f));
                add("Center", PanelUtils.totalCenterInPanel(nameLabel));
            }

            @Override
            public Component getListCellRendererComponent(JList<? extends String> list, String value, int index, boolean isSelected, boolean cellHasFocus) {
                nameLabel.setForeground(isSelected ? Theme.current().getInterfaceAccentColor() : Theme.current().getAltForegroundColor());
                nameLabel.setText(value);
                if (index != 0) {
                    setBorder(topSeparatorBorder);
                } else {
                    setBorder(emptyBorder);
                }
                return this;
            }

            static class InsetTopLineBorder extends AbstractBorder {
                private final java.awt.Color color;
                private final int gap;
                private final Insets insets;
                private final int lineOffset;

                public InsetTopLineBorder(java.awt.Color color, int gap, int totalTopSpace, int lineOffset) {
                    this.color = color;
                    this.gap = gap;
                    this.lineOffset = lineOffset;
                    this.insets = new Insets(totalTopSpace, 0, 0, 0);
                }

                @Override
                public void paintBorder(Component c, Graphics g, int x, int y, int width, int height) {
                    super.paintBorder(c, g, x, y, width, height);
                    Graphics2D g2 = (Graphics2D) g.create();
                    g2.setColor(color);

                    int lineY = y + lineOffset;
                    g2.drawLine(x + gap, lineY, x + width - gap, lineY);
                    g2.dispose();
                }

                @Override
                public Insets getBorderInsets(Component c) {
                    return insets;
                }

                @Override
                public Insets getBorderInsets(Component c, Insets insets) {
                    insets.left = this.insets.left;
                    insets.top = this.insets.top;
                    insets.right = this.insets.right;
                    insets.bottom = this.insets.bottom;
                    return insets;
                }
            }
        }
        elementList.setCellRenderer(new ListRenderer());

        mainSplitPane.setLeftComponent(listScrollPane);

        JSplitPane rightSplitPane = new JSplitPane(JSplitPane.VERTICAL_SPLIT);
        rightSplitPane.setResizeWeight(0.7);

        previewPanel = new JFXPanel();
        previewPanel.setPreferredSize(new Dimension(400, 400));
        JPanel previewContainer = new JPanel(new BorderLayout());
        previewContainer.add(previewPanel, BorderLayout.CENTER);
        rightSplitPane.setTopComponent(previewContainer);

        controlPanel = new AnimationControlPanel();
        rightSplitPane.setBottomComponent(controlPanel);

        mainSplitPane.setRightComponent(rightSplitPane);

        add(mainSplitPane, BorderLayout.CENTER);

        animationManager = new AnimationManager(previewPanel, controlPanel);

        elementList.addListSelectionListener(e -> {
            if (!e.getValueIsAdjusting() && elementList.getSelectedIndex() >= 0) {
                loadSelectedAnimation();
            }
        });
    }

    private void loadSelectedAnimation() {
        String selected = elementList.getSelectedValue();
        if (selected != null) {
            File animFile = findAnimationFile(selected);
            if (animFile != null && animFile.exists()) {
                animationManager.loadAnimations(animFile);
            }
        }
    }

    private File findAnimationFile(String fileName) {
        File animFile = new File(workspacePanel.getMCreator().getWorkspace().getFolderManager().getWorkspaceFolder(),
                "src/main/resources/data/" + workspacePanel.getMCreator().getWorkspace().getWorkspaceSettings().getModID()
                        + "/bedrock_animations/" + fileName + ".json");

        if (!animFile.exists()) {
            animFile = new File(GeneratorUtils.getSpecificRoot(workspacePanel.getMCreator().getWorkspace(),
                    workspacePanel.getMCreator().getWorkspace().getGeneratorConfiguration(), "mod_data_root"),
                    "/bedrock_animations/" + fileName + ".json");
        }

        return animFile.exists() ? animFile : null;
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
            Launcher.animations.clear();
            if (files != null) {
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
        public Component getListCellRendererComponent(JList<? extends String> list, String value, int index,
                                                      boolean isSelected, boolean cellHasFocus) {
            setText(value);
            setOpaque(true);
            setBackground(isSelected ? Theme.current().getAltBackgroundColor() : Theme.current().getBackgroundColor());
            setForeground(Theme.current().getForegroundColor());
            setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
            return this;
        }
    }

    static class AnimationControlPanel extends JPanel {
        private JComboBox<String> animationSelector;
        private JButton playButton, pauseButton, stopButton;
        private JSlider timelineSlider;
        private JLabel timeLabel;
        private JComboBox<String> loopTypeSelector;
        private JSpinner speedSpinner;
        private TimelinePanel timelinePanel;

        public AnimationControlPanel() {
            setLayout(new BorderLayout(5, 5));
            setBorder(new EmptyBorder(5, 5, 5, 5));

            JPanel topPanel = new JPanel(new BorderLayout(5, 5));

            JPanel controlsPanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 0));

            controlsPanel.add(new JLabel("Animation:"));
            animationSelector = new JComboBox<>();
            animationSelector.setPreferredSize(new Dimension(200, 25));
            controlsPanel.add(animationSelector);

            playButton = new JButton("▶");
            pauseButton = new JButton("⏸");
            stopButton = new JButton("⏹");

            playButton.setPreferredSize(new Dimension(50, 25));
            pauseButton.setPreferredSize(new Dimension(50, 25));
            stopButton.setPreferredSize(new Dimension(50, 25));

            controlsPanel.add(playButton);
            controlsPanel.add(pauseButton);
            controlsPanel.add(stopButton);

            controlsPanel.add(new JLabel("Loop:"));
            loopTypeSelector = new JComboBox<>(new String[]{"Once", "Loop", "Hold on Last Frame"});
            loopTypeSelector.setPreferredSize(new Dimension(150, 25));
            controlsPanel.add(loopTypeSelector);

            controlsPanel.add(new JLabel("Speed:"));
            speedSpinner = new JSpinner(new SpinnerNumberModel(1.0, 0.1, 5.0, 0.1));
            speedSpinner.setPreferredSize(new Dimension(60, 25));
            controlsPanel.add(speedSpinner);

            topPanel.add(controlsPanel, BorderLayout.NORTH);

            JPanel timelineContainerPanel = new JPanel(new BorderLayout(5, 5));

            timelineSlider = new JSlider(0, 100, 0);
            timelineSlider.setPaintTicks(true);
            timelineSlider.setPaintLabels(true);
            timelineSlider.setMajorTickSpacing(20);
            timelineSlider.setMinorTickSpacing(5);

            JPanel sliderPanel = new JPanel(new BorderLayout());
            sliderPanel.add(timelineSlider, BorderLayout.CENTER);

            timeLabel = new JLabel("0.00s / 0.00s");
            timeLabel.setHorizontalAlignment(SwingConstants.CENTER);
            sliderPanel.add(timeLabel, BorderLayout.SOUTH);

            timelineContainerPanel.add(sliderPanel, BorderLayout.NORTH);

            timelinePanel = new TimelinePanel();
            timelineContainerPanel.add(timelinePanel, BorderLayout.CENTER);

            topPanel.add(timelineContainerPanel, BorderLayout.CENTER);

            add(topPanel, BorderLayout.NORTH);
        }

        public JComboBox<String> getAnimationSelector() { return animationSelector; }
        public JButton getPlayButton() { return playButton; }
        public JButton getPauseButton() { return pauseButton; }
        public JButton getStopButton() { return stopButton; }
        public JSlider getTimelineSlider() { return timelineSlider; }
        public JLabel getTimeLabel() { return timeLabel; }
        public JComboBox<String> getLoopTypeSelector() { return loopTypeSelector; }
        public JSpinner getSpeedSpinner() { return speedSpinner; }
        public TimelinePanel getTimelinePanel() { return timelinePanel; }
    }

    static class TimelinePanel extends JPanel {
        private List<Float> keyframeTimes = new ArrayList<>();
        private float duration = 1.0f;
        private float currentTime = 0f;

        public TimelinePanel() {
            setPreferredSize(new Dimension(0, 60));
            setBackground(Theme.current().getBackgroundColor());
            setBorder(BorderFactory.createLineBorder(Theme.current().getForegroundColor()));
        }

        public void setKeyframes(List<Float> times, float duration) {
            this.keyframeTimes = new ArrayList<>(times);
            this.duration = duration;
            repaint();
        }

        public void setCurrentTime(float time) {
            this.currentTime = time;
            repaint();
        }

        @Override
        protected void paintComponent(Graphics g) {
            super.paintComponent(g);
            Graphics2D g2 = (Graphics2D) g;
            g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);

            int w = getWidth();
            int h = getHeight();

            // Draw timeline background
            g2.setColor(Theme.current().getAltBackgroundColor());
            g2.fillRect(5, 5, w - 10, h - 10);

            if (duration > 0) {
                // Draw keyframe markers
                g2.setColor(java.awt.Color.ORANGE);
                for (Float time : keyframeTimes) {
                    int x = (int) (5 + (time / duration) * (w - 10));
                    g2.fillRect(x - 2, 10, 4, h - 20);
                }

                // Draw current time indicator
                g2.setColor(java.awt.Color.RED);
                int currentX = (int) (5 + (currentTime / duration) * (w - 10));
                g2.setStroke(new BasicStroke(2));
                g2.drawLine(currentX, 5, currentX, h - 5);
            }
        }
    }

    static class AnimationManager {
        private JFXPanel fxPanel;
        private MinecraftPlayer playerModel;
        private AnimationTimer animationTimer;
        private Map<String, AnimationData> animations;
        private List<String> animationNames;
        private String currentAnimationName;
        private double animationTime = 0;
        private Rotate modelRotation;
        private AnimationControlPanel controlPanel;
        private boolean isPlaying = false;
        private boolean autoRotate = false;
        private double playbackSpeed = 1.0;
        private double lastMouseX = 0;
        private double lastMouseY = 0;
        private double rotationY = 0;
        private double rotationX = 0;

        public AnimationManager(JFXPanel panel, AnimationControlPanel controls) {
            this.fxPanel = panel;
            this.controlPanel = controls;
            animations = new HashMap<>();
            animationNames = new ArrayList<>();

            Platform.setImplicitExit(false);
            Platform.runLater(() -> initFX());

            setupControlListeners();
        }

        private void setupControlListeners() {
            controlPanel.getPlayButton().addActionListener(e -> play());
            controlPanel.getPauseButton().addActionListener(e -> pause());
            controlPanel.getStopButton().addActionListener(e -> stop());

            controlPanel.getAnimationSelector().addActionListener(e -> {
                int index = controlPanel.getAnimationSelector().getSelectedIndex();
                if (index >= 0 && index < animationNames.size()) {
                    currentAnimationName = animationNames.get(index);
                    stop();
                    updateTimelineInfo();
                }
            });

            controlPanel.getTimelineSlider().addChangeListener(new ChangeListener() {
                private boolean isAdjusting = false;

                @Override
                public void stateChanged(ChangeEvent e) {
                    if (controlPanel.getTimelineSlider().getValueIsAdjusting()) {
                        if (!isAdjusting) {
                            pause();
                            isAdjusting = true;
                        }
                        AnimationData anim = getCurrentAnimation();
                        if (anim != null) {
                            float newTime = (controlPanel.getTimelineSlider().getValue() / 100f) * anim.length;
                            animationTime = newTime;
                            Platform.runLater(() -> {
                                applyAnimation(anim, (float) animationTime);
                                controlPanel.getTimelinePanel().setCurrentTime((float) animationTime);
                            });
                            updateTimeLabel();
                        }
                    } else {
                        isAdjusting = false;
                    }
                }
            });

            controlPanel.getSpeedSpinner().addChangeListener(e -> {
                playbackSpeed = (Double) controlPanel.getSpeedSpinner().getValue();
            });
        }

        private AnimationData getCurrentAnimation() {
            if (currentAnimationName != null && animations.containsKey(currentAnimationName)) {
                return animations.get(currentAnimationName);
            }
            return null;
        }

        private void play() {
            isPlaying = true;
        }

        private void pause() {
            isPlaying = false;
        }

        private void stop() {
            isPlaying = false;
            animationTime = 0;
            Platform.runLater(() -> {
                if (playerModel != null) {
                    playerModel.resetPose();
                }
                controlPanel.getTimelinePanel().setCurrentTime(0);
            });
            controlPanel.getTimelineSlider().setValue(0);
            updateTimeLabel();
        }

        private void updateTimelineInfo() {
            AnimationData anim = getCurrentAnimation();
            if (anim != null) {
                controlPanel.getTimelineSlider().setMaximum(100);

                Set<Float> allTimes = new HashSet<>();
                for (BoneData bone : anim.bones.values()) {
                    for (PreviewKeyframe kf : bone.rotations) allTimes.add(kf.time);
                    for (PreviewKeyframe kf : bone.positions) allTimes.add(kf.time);
                    for (PreviewKeyframe kf : bone.scales) allTimes.add(kf.time);
                }

                controlPanel.getTimelinePanel().setKeyframes(new ArrayList<>(allTimes), anim.length);
                updateTimeLabel();
            }
        }

        private void updateTimeLabel() {
            AnimationData anim = getCurrentAnimation();
            if (anim != null) {
                controlPanel.getTimeLabel().setText(
                        String.format("%.2fs / %.2fs", animationTime, anim.length)
                );
            }
        }

        private void initFX() {
            Group root = new Group();
            Scene scene = new Scene(root, 400, 400, true, SceneAntialiasing.BALANCED);
            scene.setFill(Color.TRANSPARENT);

            playerModel = new MinecraftPlayer();
            modelRotation = new Rotate(0, Rotate.Y_AXIS);

            Scale baseScale = new Scale(0.7, 0.7, 0.7);

            playerModel.getGroup().getTransforms().clear();
            playerModel.getGroup().getTransforms().addAll(0, Arrays.asList(modelRotation, baseScale));
            playerModel.addInternalTransforms();

            root.getChildren().add(playerModel.getGroup());

            PerspectiveCamera camera = new PerspectiveCamera(true);
            camera.setTranslateZ(-80);
            camera.setTranslateY(6);
            scene.setCamera(camera);

            scene.setOnMousePressed(event -> {
                lastMouseX = event.getSceneX();
                lastMouseY = event.getSceneY();
            });

            scene.setOnMouseDragged(event -> {
                double deltaX = event.getSceneX() - lastMouseX;
                double deltaY = event.getSceneY() - lastMouseY;

                rotationY -= deltaX * 0.5;
                rotationX -= deltaY * 0.5;

                rotationX = Math.max(-90, Math.min(90, rotationX));

                lastMouseX = event.getSceneX();
                lastMouseY = event.getSceneY();
            });

            fxPanel.setScene(scene);

            animationTimer = new AnimationTimer() {
                private long lastUpdate = 0;

                @Override
                public void handle(long now) {
                    if (lastUpdate == 0) {
                        lastUpdate = now;
                        return;
                    }

                    double deltaTime = (now - lastUpdate) / 1_000_000_000.0;
                    lastUpdate = now;

                    updateAnimation(deltaTime);
                }
            };
            animationTimer.start();
        }

        private void updateAnimation(double deltaTime) {
            AnimationData anim = getCurrentAnimation();
            if (anim == null) return;

            if (isPlaying) {
                animationTime += deltaTime * playbackSpeed;

                String loopType = (String) controlPanel.getLoopTypeSelector().getSelectedItem();

                if (animationTime >= anim.length) {
                    switch (loopType) {
                        case "Loop":
                            animationTime = animationTime % anim.length;
                            break;
                        case "Hold on Last Frame":
                            animationTime = anim.length;
                            pause();
                            break;
                        case "Once":
                        default:
                            stop();
                            return;
                    }
                }

                SwingUtilities.invokeLater(() -> {
                    controlPanel.getTimelineSlider().setValue((int) ((animationTime / anim.length) * 100));
                    updateTimeLabel();
                });
            }

            applyAnimation(anim, (float) animationTime);
            controlPanel.getTimelinePanel().setCurrentTime((float) animationTime);

            if (autoRotate && !isPlaying) {
                modelRotation.setAngle(modelRotation.getAngle() + 0.5);
            } else if (!autoRotate) {
                modelRotation.setAngle(rotationY);
            }
        }

        private void applyAnimation(AnimationData anim, float time) {
            playerModel.resetPose();

            if (anim.bones.containsKey("body")) {
                BoneData rootBone = anim.bones.get("body");
                Vec3 pos = interpolate(rootBone.positions, time);
                Vec3 rot = interpolate(rootBone.rotations, time);
                Vec3 scale = interpolate(rootBone.scales, time);
                playerModel.applyRootTransform(pos, rot, scale);
            }

            if (anim.bones.containsKey("head")) {
                applyBoneTransform(anim.bones.get("head"), time, playerModel.head);
            }
            if (anim.bones.containsKey("torso")) {
                applyBoneTransform(anim.bones.get("torso"), time, playerModel.body);
            }
            if (anim.bones.containsKey("right_arm")) {
                applyBoneTransform(anim.bones.get("right_arm"), time, playerModel.rightArm);
            }
            if (anim.bones.containsKey("left_arm")) {
                applyBoneTransform(anim.bones.get("left_arm"), time, playerModel.leftArm);
            }
            if (anim.bones.containsKey("right_leg")) {
                applyBoneTransform(anim.bones.get("right_leg"), time, playerModel.rightLeg);
            }
            if (anim.bones.containsKey("left_leg")) {
                applyBoneTransform(anim.bones.get("left_leg"), time, playerModel.leftLeg);
            }
        }

        private void applyBoneTransform(BoneData bone, float time, PlayerPart part) {
            Vec3 rotation = interpolate(bone.rotations, time);
            Vec3 position = interpolate(bone.positions, time);
            Vec3 scale = interpolate(bone.scales, time);

            if (rotation != null) {
                part.setRotation(rotation.x, rotation.y, rotation.z);
            }
            if (position != null) {
                part.setPosition(position.x, position.y, position.z);
            }
            if (scale != null) {
                part.setScale(scale.x, scale.y, scale.z);
            }
        }

        private Vec3 interpolate(List<PreviewKeyframe> keyframes, float time) {
            if (keyframes.isEmpty()) return null;
            if (keyframes.size() == 1) {
                PreviewKeyframe kf = keyframes.get(0);
                return kf.value.isMolang() ? evalMolang(kf.value.molang, time) : kf.value.vector;
            }

            PreviewKeyframe lastKf = null;
            PreviewKeyframe nextKf = null;
            int lastIdx = -1;

            for (int i = 0; i < keyframes.size(); i++) {
                PreviewKeyframe kf = keyframes.get(i);
                if (time >= kf.time) {
                    lastKf = kf;
                    lastIdx = i;
                }
                if (time < kf.time) {
                    nextKf = kf;
                    break;
                }
            }

            if (lastKf == null) return null;
            Vec3 postVec = lastKf.post.isMolang() ? evalMolang(lastKf.post.molang, time) : lastKf.post.vector;
            if (nextKf == null) return postVec;

            float t1 = lastKf.time;
            float t2_ = nextKf.time;
            if (t1 == t2_) return postVec;

            float alpha = (time - t1) / (t2_ - t1);
            Vec3 v1 = postVec;
            Vec3 v2 = nextKf.pre.isMolang() ? evalMolang(nextKf.pre.molang, time) : nextKf.pre.vector;

            if (lastKf.catmullrom) {
                Vec3 p0 = v1, p1 = v1, p2 = v2, p3 = v2;
                if (lastIdx > 0) {
                    PreviewKeyframeValue kv = keyframes.get(lastIdx - 1).post;
                    p0 = kv.isMolang() ? evalMolang(kv.molang, time) : kv.vector;
                }
                if (lastIdx + 1 < keyframes.size() - 1) {
                    PreviewKeyframeValue kv = keyframes.get(lastIdx + 2).pre;
                    p3 = kv.isMolang() ? evalMolang(kv.molang, time) : kv.vector;
                }

                float t = alpha, t2 = t * t, t3 = t2 * t;
                return new Vec3(
                        0.5f * ((2 * p1.x) + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
                        0.5f * ((2 * p1.y) + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
                        0.5f * ((2 * p1.z) + (-p0.z + p2.z) * t + (2 * p0.z - 5 * p1.z + 4 * p2.z - p3.z) * t2 + (-p0.z + 3 * p1.z - 3 * p2.z + p3.z) * t3)
                );
            }

            return new Vec3(v1.x + (v2.x - v1.x) * alpha, v1.y + (v2.y - v1.y) * alpha, v1.z + (v2.z - v1.z) * alpha);
        }

        private static Vec3 evalMolang(String expr, float time) {
            expr = preprocessMolangQueries(expr, time);
            try {
                if (expr.trim().startsWith("[") && expr.trim().endsWith("]")) {
                    String inner = expr.trim().substring(1, expr.trim().length() - 1);
                    String[] parts = inner.split(",");
                    return new Vec3(
                            parts.length > 0 ? evalFloat(parts[0].trim(), time) : 0,
                            parts.length > 1 ? evalFloat(parts[1].trim(), time) : 0,
                            parts.length > 2 ? evalFloat(parts[2].trim(), time) : 0
                    );
                }
                float val = evalFloat(expr, time);
                return new Vec3(val, val, val);
            } catch (Exception e) {
                return Vec3.ZERO;
            }
        }

        private static float evalFloat(String expr, float time) {
            if (expr == null || expr.isEmpty()) return 0.0f;
            expr = expr.trim().replace(" ", "");
            String lower = expr.toLowerCase();

            if (lower.startsWith("math.sin(") && lower.endsWith(")")) {
                return (float) Math.sin(Math.toRadians(evalFloat(expr.substring(9, expr.length() - 1), time)));
            }
            if (lower.startsWith("math.cos(") && lower.endsWith(")")) {
                return (float) Math.cos(Math.toRadians(evalFloat(expr.substring(9, expr.length() - 1), time)));
            }
            if (lower.startsWith("math.tan(") && lower.endsWith(")")) {
                return (float) Math.tan(Math.toRadians(evalFloat(expr.substring(9, expr.length() - 1), time)));
            }
            if (lower.startsWith("math.abs(") && lower.endsWith(")")) {
                return Math.abs(evalFloat(expr.substring(9, expr.length() - 1), time));
            }
            if (lower.startsWith("math.sqrt(") && lower.endsWith(")")) {
                return (float) Math.sqrt(evalFloat(expr.substring(10, expr.length() - 1), time));
            }
            if (lower.startsWith("math.pow(") && lower.endsWith(")")) {
                String inner = expr.substring(9, expr.length() - 1);
                int commaPos = findTopLevelComma(inner);
                if (commaPos != -1) {
                    float base = evalFloat(inner.substring(0, commaPos), time);
                    float exp = evalFloat(inner.substring(commaPos + 1), time);
                    return (float) Math.pow(base, exp);
                }
            }
            if (lower.startsWith("math.min(") && lower.endsWith(")")) {
                String inner = expr.substring(9, expr.length() - 1);
                int commaPos = findTopLevelComma(inner);
                if (commaPos != -1) {
                    return Math.min(evalFloat(inner.substring(0, commaPos), time),
                            evalFloat(inner.substring(commaPos + 1), time));
                }
            }
            if (lower.startsWith("math.max(") && lower.endsWith(")")) {
                String inner = expr.substring(9, expr.length() - 1);
                int commaPos = findTopLevelComma(inner);
                if (commaPos != -1) {
                    return Math.max(evalFloat(inner.substring(0, commaPos), time),
                            evalFloat(inner.substring(commaPos + 1), time));
                }
            }
            if (lower.startsWith("math.clamp(") && lower.endsWith(")")) {
                String inner = expr.substring(11, expr.length() - 1);
                List<String> parts = new ArrayList<>();
                int depth = 0;
                int start = 0;
                for (int i = 0; i < inner.length(); i++) {
                    char c = inner.charAt(i);
                    if (c == '(') depth++;
                    else if (c == ')') depth--;
                    else if (c == ',' && depth == 0) {
                        parts.add(inner.substring(start, i));
                        start = i + 1;
                    }
                }
                parts.add(inner.substring(start));

                if (parts.size() == 3) {
                    float val = evalFloat(parts.get(0), time);
                    float min = evalFloat(parts.get(1), time);
                    float max = evalFloat(parts.get(2), time);
                    return Math.max(min, Math.min(max, val));
                }
            }

            int depth = 0;

            for (int i = expr.length() - 1; i >= 0; i--) {
                char c = expr.charAt(i);
                if (c == ')') depth++;
                else if (c == '(') depth--;
                else if (depth == 0) {
                    if (c == '+') {
                        return evalFloat(expr.substring(0, i), time) + evalFloat(expr.substring(i + 1), time);
                    }
                    else if (c == '-' && i > 0) {
                        char prev = expr.charAt(i - 1);
                        boolean isOperator = prev != '+' && prev != '-' && prev != '*' && prev != '/' && prev != '(' && prev != 'E' && prev != 'e';

                        if (isOperator) {
                            return evalFloat(expr.substring(0, i), time) - evalFloat(expr.substring(i + 1), time);
                        }
                    }
                }
            }

            depth = 0;
            for (int i = expr.length() - 1; i >= 0; i--) {
                char c = expr.charAt(i);
                if (c == ')') depth++;
                else if (c == '(') depth--;
                else if (depth == 0) {
                    if (c == '*') {
                        return evalFloat(expr.substring(0, i), time) * evalFloat(expr.substring(i + 1), time);
                    }
                    if (c == '/') {
                        float denominator = evalFloat(expr.substring(i + 1), time);
                        return denominator == 0 ? 0 : evalFloat(expr.substring(0, i), time) / denominator;
                    }
                }
            }

            if (expr.startsWith("-")) {
                return -evalFloat(expr.substring(1), time);
            }

            try {
                return Float.parseFloat(expr);
            } catch (NumberFormatException e) {
                return 0.0f;
            }
        }

        private static String preprocessMolangQueries(String expr, float time) {
            return expr
                    .replace("query.anim_time", String.valueOf(time))
                    .replace("query.head_x_rotation", "0")
                    .replace("query.head_y_rotation", "0")
                    .replace("query.body_x_rotation", "0")
                    .replace("query.body_y_rotation", "0")
                    .replace("query.life_time", "0")
                    .replace("query.health", "0")
                    .replace("query.max_health", "0")
                    .replace("query.is_on_ground", "0")
                    .replace("query.is_in_water", "0")
                    .replace("query.is_in_water_or_rain", "0")
                    .replace("query.is_sneaking", "0")
                    .replace("query.is_sprinting", "0")
                    .replace("query.is_swimming", "0")
                    .replace("query.is_riding", "0")
                    .replace("query.is_sleeping", "0")
                    .replace("query.is_alive", "0")
                    .replace("query.is_jumping", "0")
                    .replace("query.is_gliding", "0")
                    .replace("query.limb_swing", "0")
                    .replace("query.limb_swing_amount", "0")
                    .replace("query.modified_move_speed", "0")
                    .replace("query.walk_anim_speed", "0")
                    .replace("query.modified_distance_moved", "0")
                    .replace("query.ground_speed", "0")
                    .replace("query.vertical_speed", "0")
                    .replace("query.speed", "0")
                    .replace("query.walk_distance", "0")
                    .replace("query.hurt_time", "0")
                    .replace("query.hurt_direction", "0")
                    .replace("query.death_time", "0")
                    .replace("query.swing_progress", "0")
                    .replace("query.is_using_item", "0")
                    .replace("query.use_item_interval", "0")
                    .replace("query.is_first_person", "0")
                    .replace("query.main_hand_item_use_duration", "0")
                    .replace("query.yaw_speed", "0")
                    .replace("query.position_delta_x", "0")
                    .replace("query.position_delta_y", "0")
                    .replace("query.position_delta_z", "0");
        }

        private static int findTopLevelComma(String expr) {
            int depth = 0;
            for (int i = 0; i < expr.length(); i++) {
                char c = expr.charAt(i);
                if (c == '(') depth++;
                else if (c == ')') depth--;
                else if (c == ',' && depth == 0) return i;
            }
            return -1;
        }

        public void loadAnimations(File animFile) {
            animations.clear();
            animationNames.clear();
            animationTime = 0;
            isPlaying = false;

            try {
                Gson gson = new Gson();
                FileReader reader = new FileReader(animFile);
                JsonObject root = gson.fromJson(reader, JsonObject.class);
                reader.close();

                if (root.has("animations")) {
                    JsonObject animsObj = root.getAsJsonObject("animations");
                    for (String animName : animsObj.keySet()) {
                        JsonObject animObj = animsObj.getAsJsonObject(animName);
                        AnimationData animData = parseAnimation(animObj);
                        animations.put(animName, animData);
                        animationNames.add(animName);
                    }
                }

                // Update UI
                SwingUtilities.invokeLater(() -> {
                    controlPanel.getAnimationSelector().removeAllItems();
                    for (String name : animationNames) {
                        controlPanel.getAnimationSelector().addItem(name);
                    }
                    if (!animationNames.isEmpty()) {
                        currentAnimationName = animationNames.get(0);
                        controlPanel.getAnimationSelector().setSelectedIndex(0);
                        updateTimelineInfo();
                    }
                });
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        private AnimationData parseAnimation(JsonObject animObj) {
            AnimationData anim = new AnimationData();
            anim.length = animObj.has("animation_length") ? animObj.get("animation_length").getAsFloat() : 1.0f;

            if (animObj.has("loop")) {
                JsonElement loopType = animObj.get("loop");
                if (loopType.isJsonPrimitive() && loopType.getAsJsonPrimitive().isBoolean())
                    anim.loop = loopType.getAsBoolean();
                else if (loopType.isJsonPrimitive())
                    anim.hold_on_last_frame = true;
            }

            if (animObj.has("bones")) {
                JsonObject bonesObj = animObj.getAsJsonObject("bones");
                for (String boneName : bonesObj.keySet()) {
                    BoneData bone = parseBone(bonesObj.getAsJsonObject(boneName));
                    anim.bones.put(boneName, bone);
                }
            }

            return anim;
        }

        private BoneData parseBone(JsonObject boneObj) {
            BoneData bone = new BoneData();
            bone.rotations = parseTransform(boneObj, "rotation");
            bone.positions = parseTransform(boneObj, "position");
            bone.scales = parseTransform(boneObj, "scale");
            return bone;
        }

        private List<PreviewKeyframe> parseTransform(JsonObject bone, String key) {
            List<PreviewKeyframe> result = new ArrayList<>();
            if (!bone.has(key)) {
                return result;
            }
            JsonElement element = bone.get(key);

            if (element.isJsonArray()) {
                result.add(new PreviewKeyframe(0f, parseValue(element), null, null, false));
            } else if (element.isJsonPrimitive()) {
                result.add(new PreviewKeyframe(0f, parseValue(element), null, null, false));
            } else if (element.isJsonObject()) {
                JsonObject keyframes = element.getAsJsonObject();
                for (String timeStr : keyframes.keySet()) {
                    float time = Float.parseFloat(timeStr);
                    JsonElement frameValue = keyframes.get(timeStr);

                    if (frameValue.isJsonArray() || frameValue.isJsonPrimitive()) {
                        result.add(new PreviewKeyframe(time, parseValue(frameValue), null, null, false));
                    } else if (frameValue.isJsonObject()) {
                        JsonObject frameObj = frameValue.getAsJsonObject();
                        PreviewKeyframeValue value = frameObj.has("post") ? parseValue(frameObj.get("post")) : parseValue(frameValue);
                        PreviewKeyframeValue pre = frameObj.has("pre") ? parseValue(frameObj.get("pre")) : null;
                        PreviewKeyframeValue post = frameObj.has("post") ? parseValue(frameObj.get("post")) : null;
                        boolean catmullrom = frameObj.has("lerp_mode") && frameObj.get("lerp_mode").getAsString().equalsIgnoreCase("catmullrom");
                        result.add(new PreviewKeyframe(time, value, pre, post, catmullrom));
                    }
                }
            }
            return result;
        }

        private PreviewKeyframeValue parseValue(JsonElement element) {
            if (element.isJsonArray()) {
                JsonArray array = element.getAsJsonArray();
                boolean hasMolang = false;
                StringBuilder molangArray = new StringBuilder("[");

                for (int i = 0; i < array.size(); i++) {
                    if (i > 0) molangArray.append(",");
                    JsonElement elem = array.get(i);
                    if (elem.isJsonPrimitive()) {
                        JsonPrimitive prim = elem.getAsJsonPrimitive();
                        if (prim.isString()) {
                            hasMolang = true;
                            molangArray.append(prim.getAsString());
                        } else {
                            molangArray.append(prim.getAsFloat());
                        }
                    }
                }
                molangArray.append("]");

                if (hasMolang) return new PreviewKeyframeValue(molangArray.toString());

                float x = array.size() > 0 && array.get(0).isJsonPrimitive() ? array.get(0).getAsFloat() : 0;
                float y = array.size() > 1 && array.get(1).isJsonPrimitive() ? array.get(1).getAsFloat() : 0;
                float z = array.size() > 2 && array.get(2).isJsonPrimitive() ? array.get(2).getAsFloat() : 0;
                return new PreviewKeyframeValue(new Vec3(x, y, z));
            }

            if (element.isJsonPrimitive()) {
                JsonPrimitive prim = element.getAsJsonPrimitive();
                if (prim.isString()) return new PreviewKeyframeValue(prim.getAsString());
                float value = prim.getAsFloat();
                return new PreviewKeyframeValue(new Vec3(value, value, value));
            }

            return new PreviewKeyframeValue(Vec3.ZERO);
        }

        private static class AnimationData {
            float length;
            boolean loop = false;
            boolean hold_on_last_frame = false;
            Map<String, BoneData> bones = new HashMap<>();
        }

        private static class BoneData {
            List<PreviewKeyframe> rotations = new ArrayList<>();
            List<PreviewKeyframe> positions = new ArrayList<>();
            List<PreviewKeyframe> scales = new ArrayList<>();
        }

        public static class PreviewKeyframe {
            public final float time;
            public final PreviewKeyframeValue value;
            public final PreviewKeyframeValue pre;
            public final PreviewKeyframeValue post;
            public final boolean catmullrom;

            public PreviewKeyframe(float time, PreviewKeyframeValue value, PreviewKeyframeValue pre, PreviewKeyframeValue post, boolean catmullrom) {
                this.time = time;
                this.value = value;
                this.pre = pre != null ? pre : value;
                this.post = post != null ? post : value;
                this.catmullrom = catmullrom;
            }
        }

        public static class PreviewKeyframeValue {
            public final Vec3 vector;
            public final String molang;

            public PreviewKeyframeValue(Vec3 vector) {
                this.vector = vector;
                this.molang = null;
            }

            public PreviewKeyframeValue(String molang) {
                this.molang = molang;
                this.vector = null;
            }

            public boolean isMolang() {
                return molang != null;
            }
        }

        public static class Vec3 {
            float x, y, z;
            static final Vec3 ZERO = new Vec3(0, 0, 0);

            Vec3(float x, float y, float z) {
                this.x = x;
                this.y = y;
                this.z = z;
            }
        }
    }

    private static Image createNearestNeighborUpscaledImage(Image img, int scale) {
        if (img == null) return null;

        int oldW = (int) img.getWidth();
        int oldH = (int) img.getHeight();

        int newW = oldW * scale;
        int newH = oldH * scale;

        WritableImage newImg = new WritableImage(newW, newH);
        PixelReader reader = img.getPixelReader();
        PixelWriter writer = newImg.getPixelWriter();

        for (int y = 0; y < newH; y++) {
            for (int x = 0; x < newW; x++) {
                int oldX = x / scale;
                int oldY = y / scale;
                writer.setColor(x, y, reader.getColor(oldX, oldY));
            }
        }
        return newImg;
    }

    private static class MinecraftPlayer {
        Group group;
        PlayerPart head, body, rightArm, leftArm, rightLeg, leftLeg;

        private Rotate rootRotateX, rootRotateY, rootRotateZ;
        private Translate rootPosition;
        private Scale rootScale;

        MinecraftPlayer() {
            group = new Group();

            Image skinAtlas = null;
            try {
                ImageIcon icon = UIRES.get("16px.steve");
                java.awt.Image awtImage = icon.getImage();

                BufferedImage bimg = new BufferedImage(
                        awtImage.getWidth(null),
                        awtImage.getHeight(null),
                        BufferedImage.TYPE_INT_ARGB
                );
                Graphics2D g = bimg.createGraphics();
                g.drawImage(awtImage, 0, 0, null);
                g.dispose();

                skinAtlas = SwingFXUtils.toFXImage(bimg, null);
                skinAtlas = createNearestNeighborUpscaledImage(skinAtlas, 16);

            } catch (Exception e) {
                e.printStackTrace();
                System.err.println("Failed to load skin from UIRES. Is the key correct?");
            }
            PhongMaterial skinMaterial = new PhongMaterial();
            if (skinAtlas != null) {
                skinMaterial.setDiffuseMap(skinAtlas);
            } else {
                skinMaterial.setDiffuseColor(Color.rgb(255, 220, 177));
            }

            head = new PlayerPart(8, 8, 8, skinMaterial,
                    8, 0, 16, 0, 0, 8, 16, 8, 8, 8, 24, 8,
                    0, 0, 0, 0, -4, 0);

            body = new PlayerPart(8, 12, 4, skinMaterial,
                    20, 16, 28, 16, 16, 20, 28, 20, 20, 20, 32, 20,
                    0, 0, 0, 0, 6, 0);

            rightArm = new PlayerPart(4, 12, 4, skinMaterial,
                    44, 16, 48, 16, 40, 20, 48, 20, 44, 20, 52, 20,
                    -5, 2, 0, -1, 4, 0);

            leftArm = new PlayerPart(4, 12, 4, skinMaterial,
                    36, 48, 40, 48, 32, 52, 40, 52, 36, 52, 44, 52,
                    5, 2, 0, 1, 4, 0);

            rightLeg = new PlayerPart(4, 12, 4, skinMaterial,
                    4, 16, 8, 16, 0, 20, 8, 20, 4, 20, 12, 20,
                    -1.9, 12, 0, 0, 6, 0);

            leftLeg = new PlayerPart(4, 12, 4, skinMaterial,
                    20, 48, 24, 48, 16, 52, 24, 52, 20, 52, 28, 52,
                    1.9, 12, 0, 0, 6, 0);

            rootPosition = new Translate(0, 0, 0);
            rootRotateX = new Rotate(0, Rotate.X_AXIS);
            rootRotateY = new Rotate(0, Rotate.Y_AXIS);
            rootRotateZ = new Rotate(0, Rotate.Z_AXIS);
            rootScale = new Scale(1, 1, 1);

            group.getTransforms().addAll(rootPosition, rootRotateZ, rootRotateY, rootRotateX, rootScale);

            group.getChildren().addAll(
                    head.getGroup(),
                    body.getGroup(),
                    rightArm.getGroup(),
                    leftArm.getGroup(),
                    rightLeg.getGroup(),
                    leftLeg.getGroup()
            );

            group.setTranslateY(0);
        }

        void addInternalTransforms() {
            group.getTransforms().addAll(rootPosition, rootRotateZ, rootRotateY, rootRotateX, rootScale);
        }

        Group getGroup() {
            return group;
        }

        void applyRootTransform(AnimationManager.Vec3 pos, AnimationManager.Vec3 rot, AnimationManager.Vec3 scale) {
            if (pos != null) {
                rootPosition.setX(-pos.x);
                rootPosition.setY(-pos.y);
                rootPosition.setZ(pos.z);
            }

            if (rot != null) {
                rootRotateZ.setAngle(rot.z);
                rootRotateY.setAngle(rot.y);
                rootRotateX.setAngle(rot.x);
            }
            if (scale != null) {
                rootScale.setX(scale.x);
                rootScale.setY(scale.y);
                rootScale.setZ(scale.z);
            }
        }

        void resetRootTransform() {
            rootPosition.setX(0); rootPosition.setY(0); rootPosition.setZ(0);
            rootRotateX.setAngle(0); rootRotateY.setAngle(0); rootRotateZ.setAngle(0);
            rootScale.setX(1); rootScale.setY(1); rootScale.setZ(1);
        }

        void resetPose() {
            resetRootTransform();

            head.reset();
            body.reset();
            rightArm.reset();
            leftArm.reset();
            rightLeg.reset();
            leftLeg.reset();
        }
    }

    private static class PlayerPart {
        private Group group;
        private MeshView meshView;
        private Rotate rotateX, rotateY, rotateZ;
        private Scale scale;
        private double baseX, baseY, baseZ;

        PlayerPart(float w, float h, float d, PhongMaterial material,
                   float uvTopX, float uvTopY,
                   float uvBottomX, float uvBottomY,
                   float uvRightX, float uvRightY,
                   float uvLeftX, float uvLeftY,
                   float uvFrontX, float uvFrontY,
                   float uvBackX, float uvBackY,
                   double pivotX, double pivotY, double pivotZ,
                   double boxOffsetX, double boxOffsetY, double boxOffsetZ) {

            this.baseX = pivotX;
            this.baseY = pivotY;
            this.baseZ = pivotZ;

            final float atlasW = 64f;
            final float atlasH = 64f;

            float hw = w / 2f;
            float hh = h / 2f;
            float hd = d / 2f;

            // 8 Vertices of the box
            float[] points = {
                    -hw, -hh, -hd, // 0: Left-Top-Back
                    hw, -hh, -hd, // 1: Right-Top-Back
                    hw,  hh, -hd, // 2: Right-Bottom-Back
                    -hw,  hh, -hd, // 3: Left-Bottom-Back
                    -hw, -hh,  hd, // 4: Left-Top-Front
                    hw, -hh,  hd, // 5: Right-Top-Front
                    hw,  hh,  hd, // 6: Right-Bottom-Front
                    -hw,  hh,  hd  // 7: Left-Bottom-Front
            };

            float[] texCoords = {
                    // 0-3: Right face (+X) - (w=d, h=h)
                    (uvRightX + 0) / atlasW, (uvRightY + 0) / atlasH,
                    (uvRightX + d) / atlasW, (uvRightY + 0) / atlasH,
                    (uvRightX + 0) / atlasW, (uvRightY + h) / atlasH,
                    (uvRightX + d) / atlasW, (uvRightY + h) / atlasH,

                    // 4-7: Left face (-X) - (w=d, h=h)
                    (uvLeftX + 0) / atlasW, (uvLeftY + 0) / atlasH,
                    (uvLeftX + d) / atlasW, (uvLeftY + 0) / atlasH,
                    (uvLeftX + 0) / atlasW, (uvLeftY + h) / atlasH,
                    (uvLeftX + d) / atlasW, (uvLeftY + h) / atlasH,

                    // 8-11: Top face (-Y) - (w=w, h=d)
                    (uvTopX + 0) / atlasW, (uvTopY + 0) / atlasH,
                    (uvTopX + w) / atlasW, (uvTopY + 0) / atlasH,
                    (uvTopX + 0) / atlasW, (uvTopY + d) / atlasH,
                    (uvTopX + w) / atlasW, (uvTopY + d) / atlasH,

                    // 12-15: Bottom face (+Y) - (w=w, h=d)
                    (uvBottomX + 0) / atlasW, (uvBottomY + 0) / atlasH,
                    (uvBottomX + w) / atlasW, (uvBottomY + 0) / atlasH,
                    (uvBottomX + 0) / atlasW, (uvBottomY + d) / atlasH,
                    (uvBottomX + w) / atlasW, (uvBottomY + d) / atlasH,

                    // 16-19: Front face (+Z) - (w=w, h=h)
                    (uvFrontX + 0) / atlasW, (uvFrontY + 0) / atlasH,
                    (uvFrontX + w) / atlasW, (uvFrontY + 0) / atlasH,
                    (uvFrontX + 0) / atlasW, (uvFrontY + h) / atlasH,
                    (uvFrontX + w) / atlasW, (uvFrontY + h) / atlasH,

                    // 20-23: Back face (-Z) - (w=w, h=h)
                    (uvBackX + w) / atlasW, (uvBackY + 0) / atlasH,
                    (uvBackX + 0) / atlasW, (uvBackY + 0) / atlasH,
                    (uvBackX + w) / atlasW, (uvBackY + h) / atlasH,
                    (uvBackX + 0) / atlasW, (uvBackY + h) / atlasH,
            };

            // Faces (12 triangles, 2 per face)
            int[] faces = {
                    // Right (+X) face: vertices
                    5, 0,  1, 1,  6, 2,
                    1, 1,  2, 3,  6, 2,
                    // Left (-X) face: vertices
                    0, 4,  4, 5,  3, 6,
                    4, 5,  7, 7,  3, 6,
                    // Top (-Y) face: vertices
                    4, 10, 1, 9,  5, 11,
                    4, 10, 0, 8,  1, 9,
                    // Bottom (+Y) face: vertices
                    7, 12, 6, 13, 3, 14,
                    6, 13, 2, 15, 3, 14,
                    // Back (-Z) face: vertices
                    1, 16, 0, 17, 2, 18,
                    0, 17, 3, 19, 2, 18,
                    // Front (+Z) face: vertices
                    4, 20, 5, 21, 6, 23,
                    4, 20, 6, 23, 7, 22
            };

            TriangleMesh mesh = new TriangleMesh();
            mesh.getPoints().addAll(points);
            mesh.getTexCoords().addAll(texCoords);
            mesh.getFaces().addAll(faces);

            mesh.getFaceSmoothingGroups().addAll(0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5);

            meshView = new MeshView(mesh);
            meshView.setMaterial(material);

            meshView.setTranslateX(boxOffsetX);
            meshView.setTranslateY(boxOffsetY);
            meshView.setTranslateZ(boxOffsetZ);

            rotateX = new Rotate(0, Rotate.X_AXIS);
            rotateY = new Rotate(0, Rotate.Y_AXIS);
            rotateZ = new Rotate(0, Rotate.Z_AXIS);
            scale = new Scale(1, 1, 1);

            group = new Group(meshView);
            group.getTransforms().addAll(rotateZ, rotateY, rotateX, scale);

            group.setTranslateX(baseX);
            group.setTranslateY(baseY);
            group.setTranslateZ(baseZ);
        }

        void setRotation(double rx, double ry, double rz) {
            rotateX.setAngle(rx);
            rotateY.setAngle(ry);
            rotateZ.setAngle(rz);
        }

        void setPosition(double x, double y, double z) {
            group.setTranslateX(baseX + x);
            group.setTranslateY(baseY - y);
            group.setTranslateZ(baseZ + z);
        }

        void setScale(double sx, double sy, double sz) {
            scale.setX(sx);
            scale.setY(sy);
            scale.setZ(sz);
        }

        Group getGroup() {
            return group;
        }

        void reset() {
            setRotation(0, 0, 0);
            setPosition(0, 0, 0);
            setScale(1, 1, 1);
        }
    }
}