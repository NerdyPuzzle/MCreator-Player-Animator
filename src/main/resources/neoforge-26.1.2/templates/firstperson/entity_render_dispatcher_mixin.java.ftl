package ${package}.mixin;

@Mixin(EntityRenderDispatcher.class)
public abstract class EntityRenderDispatcherMixin {
    private static Minecraft mc = Minecraft.getInstance();

	@Inject(method = "submit", at = @At("HEAD"), cancellable = true)
	private static void renderShadow(EntityRenderState entityRenderState, CameraRenderState camera, double x, double y, double z, PoseStack poseStack, SubmitNodeCollector submitNodeCollector, CallbackInfo ci) {
		if (entityRenderState instanceof AvatarRenderState state) {
		    Player player = (Player) state.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		    if (player.getPersistentData().getBooleanOr("FirstPersonAnimation", false) && mc.options.getCameraType().isFirstPerson() && player == mc.player && (mc.screen == null || mc.screen instanceof ChatScreen)) {
			    state.shadowPieces.clear();
		    }
		}
	}
}