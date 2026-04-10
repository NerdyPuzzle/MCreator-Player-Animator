package ${package}.mixin;

@Mixin(LivingEntityRenderer.class)
public abstract class LivingEntityRendererMixin {
	private String master = null;
	private Minecraft mc = Minecraft.getInstance();

	@ModifyExpressionValue(
		  method = "render(Lnet/minecraft/client/renderer/entity/state/LivingEntityRenderState;Lcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;I)V",
		  at = @At(value = "FIELD", target = "Lnet/minecraft/client/renderer/entity/LivingEntityRenderer;layers:Ljava/util/List;", opcode = Opcodes.GETFIELD))
	private List<Object> filterLayers(List<Object> originalLayers, LivingEntityRenderState entityRenderState, PoseStack poseStack, MultiBufferSource multiBufferSource, int i) {
	   if (master == null) {
		  if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			 master = "${modid}";
		  else
			 return originalLayers;
	   }
	   if (!master.equals("${modid}")) {
		  return originalLayers;
	   }
	   if (entityRenderState instanceof PlayerRenderState renderState && mc.options.getCameraType().isFirstPerson()) {
		  Player player = (Player) renderState.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		  if (player == null)
			 return originalLayers;
		  if (mc.player == player && (mc.screen == null || mc.screen instanceof ChatScreen)) {
			 CompoundTag playerData = player.getPersistentData();
			 if (playerData.getBooleanOr("FirstPersonAnimation", false)) {
				playerData.putInt("setNullRender", 4);
				return originalLayers.stream().filter(layer -> layer instanceof PlayerItemInHandLayer).toList();
			 }
			 else if (playerData.contains("setNullRender")) {
				int ticks = playerData.getIntOr("setNullRender", 0);
				if (ticks <= 0) {
				   playerData.remove("setNullRender");
				} else {
				   playerData.putInt("setNullRender", ticks - 1);
				   return List.of();
				}
			 }
		  }
	   }
	   return originalLayers;
	}
}