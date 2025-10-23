package ${package}.mixin;

@Mixin(PlayerModel.class)
public abstract class PlayerAnimationMixin<T extends LivingEntity> {
	private String master = null;

	@Inject(method = "setupAnim", at = @At(value = "HEAD"))
	public void setupPivot(T entityIn, float limbSwing, float limbSwingAmount, float ageInTicks, float netHeadYaw, float headPitch, CallbackInfo ci) {
		if (master == null)
			master = "${modid}";
		PlayerModel<T> model = (PlayerModel<T>) (Object) this;
		Player player = null;
		if (entityIn instanceof Player player_)
		    player = player_;
		else
		    return;
		${JavaModName}PlayerAnimationAPI.PlayerAnimation animation = ${JavaModName}PlayerAnimationAPI.active_animations.get(player);
		if (animation == null)
	        return;
	    if (animation.bones.get("left_arm") != null || animation.bones.get("torso") != null || animation.bones.get("right_arm") != null)
		    model.attackTime = 0;
		model.crouching = false;
		resetModelPose(model);
	}

	@Inject(method = "setupAnim", at = @At(value = "TAIL"))
	public void setupAnim(T entityIn, float limbSwing, float limbSwingAmount, float ageInTicks, float netHeadYaw, float headPitch, CallbackInfo ci) {
		if (!master.equals("${modid}")) {
		    if (!${JavaModName}PlayerAnimationAPI.animations.isEmpty())
		        ${JavaModName}PlayerAnimationAPI.animations.clear();
			return;
	    }
		PlayerModel<T> model = (PlayerModel<T>) (Object) this;
		Player player = null;
		if (entityIn instanceof Player player_)
		    player = player_;
		else
		    return;
		CompoundTag data = player.getPersistentData();
		String playingAnimation = data.getString("PlayerCurrentAnimation");
		boolean overrideAnimation = data.getBoolean("OverrideCurrentAnimation");
		if (data.getBoolean("ResetPlayerAnimation")) {
		    data.remove("ResetPlayerAnimation");
		    resetModelPose(model);
		    ${JavaModName}PlayerAnimationAPI.active_animations.put(player, null);
		}
		if (playingAnimation.isEmpty()) {
			return;
		}
		if (overrideAnimation) {
			data.putBoolean("OverrideCurrentAnimation", false);
			data.remove("PlayerAnimationProgress");
			${JavaModName}PlayerAnimationAPI.active_animations.put(player, null);
		}
		${JavaModName}PlayerAnimationAPI.PlayerAnimation animation = ${JavaModName}PlayerAnimationAPI.active_animations.get(player);
		if (animation == null) {
			animation = ${JavaModName}PlayerAnimationAPI.animations.get(playingAnimation);
			${JavaModName}PlayerAnimationAPI.active_animations.put(player, animation);
		}
		float animationProgress;
		if (!data.contains("PlayerAnimationProgress")) {
			animationProgress = 0f;
			data.putFloat("PlayerAnimationProgress", animationProgress);
			data.putFloat("LastTickTime", ageInTicks);
		} else {
			animationProgress = data.getFloat("PlayerAnimationProgress");
			float lastTickTime = data.getFloat("LastTickTime");
			float deltaTime = (ageInTicks - lastTickTime) / 20f; // Convert ticks to seconds
			animationProgress += deltaTime;
			data.putFloat("PlayerAnimationProgress", animationProgress);
            data.putFloat("LastTickTime", ageInTicks);
			if (animationProgress >= animation.length) {
				if (!animation.hold_on_last_frame && !animation.loop) {
					data.remove("PlayerCurrentAnimation");
					data.remove("PlayerAnimationProgress");
				    data.putBoolean("ResetPlayerAnimation", true);
				    ${JavaModName}PlayerAnimationAPI.active_animations.put(player, null);
				    animationProgress = animation.length;
				} else if (animation.hold_on_last_frame) {
				    data.putFloat("PlayerAnimationProgress", animation.length);
				} else if (animation.loop) {
				    data.remove("PlayerAnimationProgress");
				}
			}
		}
		// Apply each bone's transformations
		for (Map.Entry<String, ${JavaModName}PlayerAnimationAPI.PlayerBone> entry : animation.bones.entrySet()) {
			String boneName = entry.getKey();
			${JavaModName}PlayerAnimationAPI.PlayerBone bone = entry.getValue();
			ModelPart modelPart = getModelPart(model, boneName);
			if (modelPart == null)
				continue;
			// Apply rotation
			Vec3 rotation = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.rotations, animationProgress);
			if (rotation != null) {
				modelPart.xRot = (float) Math.toRadians(rotation.x);
				modelPart.yRot = (float) Math.toRadians(rotation.y);
				modelPart.zRot = (float) Math.toRadians(rotation.z);
			}
			// Apply position (don't apply if null - keep default position)
			Vec3 position = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.positions, animationProgress);
			if (position != null) {
				// Position offsets are relative, not absolute
				modelPart.x += (float) position.x;
				modelPart.y -= (float) position.y;
				modelPart.z += (float) position.z;
			}
			// Apply scale
			Vec3 scale = ${JavaModName}PlayerAnimationAPI.PlayerBone.interpolate(bone.scales, animationProgress);
			if (scale != null) {
				modelPart.xScale = (float) scale.x;
				modelPart.yScale = (float) scale.y;
				modelPart.zScale = (float) scale.z;
			}
		}
		model.leftPants.copyFrom(model.leftLeg);
		model.rightPants.copyFrom(model.rightLeg);
		model.leftSleeve.copyFrom(model.leftArm);
		model.rightSleeve.copyFrom(model.rightArm);
		model.jacket.copyFrom(model.body);
		model.hat.copyFrom(model.head);
	}

	private void resetModelPose(PlayerModel<T> model) {
        model.leftLeg.setPos(1.9F, 12.0F, 0.0F);
        model.rightLeg.setPos(- 1.9F, 12.0F, 0.0F);
        model.head.setPos(0.0F, 0.0F, 0.0F);
        model.rightArm.z = 0.0F;
        model.rightArm.x = - 5.0F;
        model.leftArm.z = 0.0F;
        model.leftArm.x = 5.0F;
        model.body.xRot = 0.0F;
        model.rightLeg.z = 0.1F;
        model.leftLeg.z = 0.1F;
        model.rightLeg.y = 12.0F;
        model.leftLeg.y = 12.0F;
        model.head.y = 0.0F;
        model.head.zRot = 0f;
        model.body.y = 0.0F;
        model.body.x = 0f;
        model.body.z = 0f;
        model.body.yRot = 0;
        model.body.zRot = 0;
        model.head.xScale = ModelPart.DEFAULT_SCALE;
        model.head.yScale = ModelPart.DEFAULT_SCALE;
        model.head.zScale = ModelPart.DEFAULT_SCALE;
        model.body.xScale = ModelPart.DEFAULT_SCALE;
        model.body.yScale = ModelPart.DEFAULT_SCALE;
        model.body.zScale = ModelPart.DEFAULT_SCALE;
        model.rightArm.xScale = ModelPart.DEFAULT_SCALE;
        model.rightArm.yScale = ModelPart.DEFAULT_SCALE;
        model.rightArm.zScale = ModelPart.DEFAULT_SCALE;
        model.leftArm.xScale = ModelPart.DEFAULT_SCALE;
        model.leftArm.yScale = ModelPart.DEFAULT_SCALE;
        model.leftArm.zScale = ModelPart.DEFAULT_SCALE;
        model.rightLeg.xScale = ModelPart.DEFAULT_SCALE;
        model.rightLeg.yScale = ModelPart.DEFAULT_SCALE;
        model.rightLeg.zScale = ModelPart.DEFAULT_SCALE;
        model.leftLeg.xScale = ModelPart.DEFAULT_SCALE;
        model.leftLeg.yScale = ModelPart.DEFAULT_SCALE;
        model.leftLeg.zScale = ModelPart.DEFAULT_SCALE;
	}

	private ModelPart getModelPart(PlayerModel<T> model, String boneName) {
		switch (boneName) {
			case "torso" :
				return model.body;
			case "head" :
				return model.head;
			case "right_arm" :
				return model.rightArm;
			case "left_arm" :
				return model.leftArm;
			case "right_leg" :
				return model.rightLeg;
			case "left_leg" :
				return model.leftLeg;
			default :
				return null;
		}
	}
}