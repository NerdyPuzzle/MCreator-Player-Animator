package ${package}.mixin;

@Mixin(LivingEntityRenderer.class)
public abstract class LivingEntityRendererMixin {
    private String master = null;
    private Minecraft mc = Minecraft.getInstance();

    @Shadow @Final protected List<Object> layers;

    @Redirect(
            method = "render(Lnet/minecraft/world/entity/LivingEntity;FFLcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;I)V",
    at = @At(value = "FIELD", target = "Lnet/minecraft/client/renderer/entity/LivingEntityRenderer;layers:Ljava/util/List;", opcode = Opcodes.GETFIELD))
    private List<Object> filterLayers(LivingEntityRenderer instance, LivingEntity entity, float f, float g, PoseStack poseStack, MultiBufferSource multiBufferSource, int i) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return layers;
		}
		if (!master.equals("${modid}")) {
			return layers;
	    }
        if (entity instanceof Player player && mc.options.getCameraType().isFirstPerson()) {
			if (mc.player == player && (mc.screen == null || mc.screen instanceof ChatScreen)) {
				CompoundTag playerData = player.getPersistentData();
				if (playerData.getBoolean("FirstPersonAnimation")) {
					playerData.putInt("setNullRender", 4);
					return layers.stream().filter(layer -> layer instanceof PlayerItemInHandLayer).toList();
				}
				else if (playerData.contains("setNullRender")) {
					if (playerData.getInt("setNullRender") <= 0)
						playerData.remove("setNullRender");
					else {
						playerData.putInt("setNullRender", playerData.getInt("setNullRender") - 1);
						return List.of();
					}
				}
			}
        }
        return layers;
    }
}