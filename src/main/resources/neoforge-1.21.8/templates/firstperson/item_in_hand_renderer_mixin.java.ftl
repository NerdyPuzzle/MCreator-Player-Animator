package ${package}.mixin;

@Mixin(ItemInHandRenderer.class)
public abstract class ItemInHandRendererMixin {
	@Inject(method = "renderHandsWithItems", at = @At("HEAD"), cancellable = true)
	private void renderHandsWithItems(float f, PoseStack poseStack, MultiBufferSource.BufferSource bufferSource, LocalPlayer localPlayer, int i, CallbackInfo ci) {
		if (localPlayer instanceof Player player && player.getPersistentData().getBooleanOr("FirstPersonAnimation", false) && Minecraft.getInstance().player == player) {
			ci.cancel();
		}
	}
}