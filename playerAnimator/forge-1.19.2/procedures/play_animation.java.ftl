		if (${input$entity} == null)
			return;
			if (${input$entity} instanceof AbstractClientPlayer){ 
       var animation = SetupAnimationsProcedure.animationData.get((AbstractClientPlayer) ${input$entity});
            if (animation != null ${field$active}) {
                animation.setAnimation(new KeyframeAnimationPlayer(PlayerAnimationRegistry.getAnimation(new ResourceLocation("${modid}", ${input$animation}))));
            }
	}
