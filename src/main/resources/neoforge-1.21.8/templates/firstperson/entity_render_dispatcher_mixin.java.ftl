package ${package}.mixin;

@Mixin(EntityRenderDispatcher.class)
public abstract class EntityRenderDispatcherMixin {
	@Inject(method = "renderShadow", at = @At("HEAD"), cancellable = true)
	private static void renderShadow(PoseStack poseStack, MultiBufferSource multiBufferSource, EntityRenderState entityRenderState, float g, LevelReader levelReader, float h, CallbackInfo ci) {
		if (entityRenderState instanceof PlayerRenderState state) {
		    Minecraft mc = Minecraft.getInstance();
		    Player player = (Player) state.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		    if (player.getPersistentData().getBooleanOr("FirstPersonAnimation", false) && mc.options.getCameraType().isFirstPerson() && player == mc.player) {
			    ci.cancel();
		    }
		}
	}
}