package ${package}.mixin;

@Mixin(LevelExtractor.class)
public abstract class LevelExtractorMixin {
    private String master = null;
    private Minecraft mc = Minecraft.getInstance();

	@Inject(method = "extractVisibleEntities", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/Camera;isDetached()Z"))
	private void fakeThirdPersonMode(Camera camera, Frustum frustum, DeltaTracker deltaTracker, LevelRenderState renderState, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}")) {
			return;
	    }
		if (camera.entity() instanceof Player player && player.getPersistentData().getBooleanOr("FirstPersonAnimation", false) && mc.player == player && (mc.gui.screen() == null || mc.gui.screen() instanceof ChatScreen)) {
			((CameraAccessor) camera).setDetached(true);
		}
	}

	@Inject(method = "extractVisibleEntities", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/Camera;isDetached()Z", shift = At.Shift.AFTER))
	private void resetThirdPerson(Camera camera, Frustum frustum, DeltaTracker deltaTracker, LevelRenderState renderState, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}")) {
			return;
	    }
		((CameraAccessor) camera).setDetached(false);
	}
}