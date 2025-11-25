package ${package}.mixin;

@Mixin(HumanoidArmorLayer.class)
public abstract class HumanoidArmorLayerMixin<S extends HumanoidRenderState, M extends HumanoidModel<S>, A extends HumanoidModel<S>> {
    private String master = null;
    private Player player = null;
    private Minecraft mc = Minecraft.getInstance();

	@Inject(method = "Lnet/minecraft/client/renderer/entity/layers/HumanoidArmorLayer;render(Lcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;ILnet/minecraft/client/renderer/entity/state/HumanoidRenderState;FF)V", at = @At("HEAD"))
	private void render(PoseStack poseStack, MultiBufferSource bufferSource, int packedLight, S renderState, float yRot, float xRot, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}")) {
			return;
	    }
		if (renderState instanceof PlayerRenderState state) {
		    Player player = (Player) state.getRenderData(${JavaModName}PlayerAnimationAPI.ClientAttachments.PLAYER);
		    if (player == null)
		        return;
			this.player = player;
		}
	}

	@Inject(method = "setPartVisibility", at = @At("TAIL"))
	private void setPartVisibility(A model, EquipmentSlot slot, CallbackInfo ci) {
		if (master == null) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
			    master = "${modid}";
			else
			    return;
		}
		if (!master.equals("${modid}")) {
			return;
	    }
	    if (model.hat.skipDraw)
	        hideArmorParts(model, false);
	    if (player == null)
	        return;
	    CompoundTag playerData = player.getPersistentData();
	    if (player != null && player.getPersistentData().getBooleanOr("FirstPersonAnimation", false) && mc.options.getCameraType().isFirstPerson() && mc.player == player && mc.screen == null) {
	        hideArmorParts(model, true);
	        playerData.putInt("setNullRender", 5);
	    } else if (playerData.contains("setNullRender")) {
	        hideArmorParts(model, true);
	        playerData.putInt("setNullRender", playerData.getIntOr("setNullRender", 0) - 1);
	        if (playerData.getIntOr("setNullRender", 0) <= 0)
	            playerData.remove("setNullRender");
	    }
	}

	private void hideArmorParts(HumanoidModel armorModel, boolean hide) {
		armorModel.head.skipDraw = hide;
		armorModel.body.skipDraw = hide;
		armorModel.leftLeg.skipDraw = hide;
		armorModel.rightLeg.skipDraw = hide;
		armorModel.hat.skipDraw = hide;
	}
}