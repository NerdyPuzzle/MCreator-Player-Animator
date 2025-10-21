if (${input$entity} instanceof Player) {
    if (${input$entity}.level().isClientSide()) {
        CompoundTag data = ${input$entity}.getPersistentData();
        data.remove("PlayerCurrentAnimation");
        data.remove("PlayerAnimationProgress");
        data.putBoolean("ResetPlayerAnimation", true);
    } else {
        PacketDistributor.sendToPlayersInDimension((ServerLevel) ${input$entity}.level(), new PlayPlayerAnimationMessage(${input$entity}.getId(), "", false));
    }
}