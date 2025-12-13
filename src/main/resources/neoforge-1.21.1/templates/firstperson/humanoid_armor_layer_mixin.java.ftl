package ${package}.mixin;

@Mixin(HumanoidArmorLayer.class)
public abstract class HumanoidArmorLayerMixin<T extends LivingEntity, M extends HumanoidModel<T>, A extends HumanoidModel<T>> {
    private String master = null;
    private Player player = null;
    private Minecraft mc = Minecraft.getInstance();

	@Inject(method = "Lnet/minecraft/client/renderer/entity/layers/HumanoidArmorLayer;render(Lcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;ILnet/minecraft/world/entity/LivingEntity;FFFFFF)V", at = @At("HEAD"))
	private void render(PoseStack poseStack, MultiBufferSource buffer, int packedLight, LivingEntity livingEntity, float limbSwing, float limbSwingAmount, float partialTicks, float ageInTicks, float netHeadYaw, float headPitch, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}")) {
			return;
	    }
		if (livingEntity instanceof Player player) {
			this.player = player;
		}
	}

	@Inject(method = "Lnet/minecraft/client/renderer/entity/layers/HumanoidArmorLayer;setPartVisibility(Lnet/minecraft/client/model/HumanoidModel;Lnet/minecraft/world/entity/EquipmentSlot;)V", at = @At("TAIL"))
	private void setPartVisibility(HumanoidModel model, EquipmentSlot slot, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}")) {
			return;
	    }
	    if (player == null)
	        return;
	    CompoundTag playerData = player.getPersistentData();
	    if (player != null && player.getPersistentData().getBoolean("FirstPersonAnimation") && mc.options.getCameraType().isFirstPerson() && mc.player == player && mc.screen == null) {
	        hideArmorParts(model);
	        playerData.putInt("setNullRender", 5);
	    } else if (playerData.contains("setNullRender")) {
	        hideArmorParts(model);
	        playerData.putInt("setNullRender", playerData.getInt("setNullRender") - 1);
	        if (playerData.getInt("setNullRender") <= 0)
	            playerData.remove("setNullRender");
	    }
	}

	private void hideArmorParts(HumanoidModel armorModel) {
		M playerModel = (M) ((HumanoidArmorLayer) (Object) this).getParentModel();
		armorModel.head.visible = false;
		armorModel.body.visible = false;
		armorModel.leftLeg.visible = false;
		armorModel.rightLeg.visible = false;
		armorModel.hat.visible = false;
		armorModel.rightArm.visible = playerModel.rightArm.visible;
		armorModel.leftArm.visible = playerModel.leftArm.visible;
	}
}