package ${package}.mixin;

@Mixin(ItemInHandLayer.class)
public abstract class ItemInHandLayerMixin {
	private String master = null;

	@Inject(method = "submitArmWithItem", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/renderer/item/ItemStackRenderState;submit(Lcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/SubmitNodeCollector;III)V"))
	private void animateItem(ArmedEntityRenderState renderState, ItemStackRenderState itemStackRenderState, ItemStack itemStack, HumanoidArm arm, PoseStack poseStack, SubmitNodeCollector collector, int packedLight, CallbackInfo ci) {
		if (master == null) {
			if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
				master = "${modid}";
			else
				return;
		}
		if (!master.equals("${modid}")) {
			return;
		}
		if (renderState instanceof AvatarRenderState state) {
		    Player player = (Player) renderState.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		    if (player == null)
		        return;
			${JavaModName}PlayerAnimationAPI.PlayerAnimation animation = ${JavaModName}PlayerAnimationAPI.active_animations.get(player);
			if (animation == null)
				return;
			${JavaModName}PlayerAnimationAPI.PlayerBone bone = animation.bones.get(arm == HumanoidArm.LEFT ? "left_item" : "right_item");
			if (bone == null)
				return;
			float animationProgress = player.getPersistentData().getFloatOr("PlayerAnimationProgress", 0);
			Vec3 scale = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.scales, animationProgress, player);
			if (scale != null) {
				poseStack.scale((float) scale.x, (float) scale.y, (float) scale.z);
			}
			Vec3 position = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.positions, animationProgress, player);
			if (position != null) {
				poseStack.translate((float) -position.x * 0.0625f, (float) -position.z * 0.0625f, (float) position.y * 0.0625f);
			}
			Vec3 rotation = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.rotations, animationProgress, player);
			if (rotation != null) {
				poseStack.mulPose(Axis.ZP.rotationDegrees((float) rotation.y));
				poseStack.mulPose(Axis.YP.rotationDegrees((float) -rotation.z));
				poseStack.mulPose(Axis.XP.rotationDegrees((float) -rotation.x));
			}
		}
	}
}