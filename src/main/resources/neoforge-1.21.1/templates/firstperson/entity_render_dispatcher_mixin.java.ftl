package ${package}.mixin;

@Mixin(EntityRenderDispatcher.class)
public abstract class EntityRenderDispatcherMixin {
    private static Minecraft mc = Minecraft.getInstance();
    
	@Inject(method = "renderShadow", at = @At("HEAD"), cancellable = true)
	private static void renderShadow(PoseStack poseStack, MultiBufferSource bufferSource, Entity entity, float opacity, float tickDelta, LevelReader world, float radius, CallbackInfo ci) {
		if (entity instanceof Player player && mc.options.getCameraType().isFirstPerson() && player == mc.player && mc.screen == null) {
			if (player.getPersistentData().getBoolean("FirstPersonAnimation"))
			    ci.cancel();
		}
	}
}