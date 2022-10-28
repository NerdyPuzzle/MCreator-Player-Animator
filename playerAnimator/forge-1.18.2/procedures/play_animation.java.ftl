			if (${input$entity} instanceof Player){ 
       var animation = SetupAnimationsProcedure.animationData.get((Player) ${input$entity});
            if (animation != null ${field$active}) {
                animation.setAnimation(new KeyframeAnimationPlayer(PlayerAnimationRegistry.getAnimation(new ResourceLocation("${modid}", ${input$animation}))));
            }
	}
