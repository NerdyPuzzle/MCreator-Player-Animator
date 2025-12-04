package ${package}.mixin;

@Mixin(PlayerRenderer.class)
public abstract class PlayerAnimationRendererMixin extends LivingEntityRenderer<AbstractClientPlayer, PlayerRenderState, PlayerModel> {
    private String master = null;
    private Minecraft mc = Minecraft.getInstance();

    public PlayerAnimationRendererMixin(EntityRendererProvider.Context context, boolean slim) {
        super(null, null, 0.5f);
    }

    @Inject(method = "Lnet/minecraft/client/renderer/entity/player/PlayerRenderer;setupRotations(Lnet/minecraft/client/renderer/entity/state/PlayerRenderState;Lcom/mojang/blaze3d/vertex/PoseStack;FF)V", at = @At("RETURN"))
    private void setupRotations(PlayerRenderState renderState, PoseStack poseStack, float bodyRot, float scale_, CallbackInfo ci) {
		Player player = (Player) renderState.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		if (player == null)
		    return;
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}"))
			return;
	    ${JavaModName}PlayerAnimationAPI.PlayerAnimation animation = ${JavaModName}PlayerAnimationAPI.active_animations.get(player);
	    if (animation == null)
	        return;
	    ${JavaModName}PlayerAnimationAPI.PlayerBone bone = animation.bones.get("body");
        if (bone == null)
            return;
		boolean firstPerson = player.getPersistentData().getBooleanOr("FirstPersonAnimation", false) && mc.options.getCameraType().isFirstPerson() && player == mc.player && mc.screen == null;
        float animationProgress = player.getPersistentData().getFloatOr("PlayerAnimationProgress", 0);
		Vec3 scale = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.scales, animationProgress, player);
		if (scale != null) {
			poseStack.scale((float) scale.x, (float) scale.y, (float) scale.z);
		}
		Vec3 position = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.positions, animationProgress, player);
		if (position != null) {
		    if (!firstPerson)
			    poseStack.translate((float) -position.x * 0.0625f, (float) (position.y * 0.0625f) + 0.75f, (float) position.z * 0.0625f);
		}
		Vec3 rotation = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.rotations, animationProgress, player);
		if (rotation != null) {
		    if (!firstPerson)
			    poseStack.mulPose(Axis.ZP.rotationDegrees((float) rotation.z));
			poseStack.mulPose(Axis.YP.rotationDegrees((float) -rotation.y));
			if (!firstPerson)
			    poseStack.mulPose(Axis.XP.rotationDegrees((float) -rotation.x));
		}
		if (position != null) {
		    if (!firstPerson)
		        poseStack.translate(0, -0.75f, 0);
		}
	}
}