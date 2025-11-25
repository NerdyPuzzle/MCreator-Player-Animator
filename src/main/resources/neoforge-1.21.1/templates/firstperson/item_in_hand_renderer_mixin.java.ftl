package ${package}.mixin;

@Mixin(ItemInHandRenderer.class)
public abstract class ItemInHandRendererMixin {
    private Minecraft mc = Minecraft.getInstance();

	@Inject(method = "renderHandsWithItems", at = @At("HEAD"), cancellable = true)
	private void renderHandsWithItems(float f, PoseStack poseStack, MultiBufferSource.BufferSource bufferSource, LocalPlayer localPlayer, int i, CallbackInfo ci) {
		if (localPlayer instanceof Player player && player.getPersistentData().getBoolean("FirstPersonAnimation") && mc.player == player && mc.screen == null) {
			ci.cancel();
		}
	}
}