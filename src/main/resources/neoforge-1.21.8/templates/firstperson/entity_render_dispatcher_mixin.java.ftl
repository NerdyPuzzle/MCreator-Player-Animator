package ${package}.mixin;

@Mixin(EntityRenderDispatcher.class)
public abstract class EntityRenderDispatcherMixin {
    private static Minecraft mc = Minecraft.getInstance();

	@Inject(method = "renderShadow", at = @At("HEAD"), cancellable = true)
	private static void renderShadow(PoseStack poseStack, MultiBufferSource multiBufferSource, EntityRenderState entityRenderState, float g, LevelReader levelReader, float h, CallbackInfo ci) {
		if (entityRenderState instanceof PlayerRenderState state) {
		    Player player = (Player) state.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		    if (player.getPersistentData().getBooleanOr("FirstPersonAnimation", false) && mc.options.getCameraType().isFirstPerson() && player == mc.player && mc.screen == null) {
			    ci.cancel();
		    }
		}
	}
}