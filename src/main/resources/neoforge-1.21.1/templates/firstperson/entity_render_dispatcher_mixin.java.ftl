package ${package}.mixin;

@Mixin(EntityRenderDispatcher.class)
public abstract class EntityRenderDispatcherMixin {
	@Inject(method = "renderShadow", at = @At("HEAD"), cancellable = true)
	private static void renderShadow(PoseStack poseStack, MultiBufferSource bufferSource, Entity entity, float opacity, float tickDelta, LevelReader world, float radius, CallbackInfo ci) {
		Minecraft mc = Minecraft.getInstance();
		if (entity instanceof Player player && mc.options.getCameraType().isFirstPerson() && player == mc.player) {
			if (player.getPersistentData().getBoolean("FirstPersonAnimation"))
			    ci.cancel();
		}
	}
}