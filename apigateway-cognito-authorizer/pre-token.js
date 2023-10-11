exports.handler = async (event) => {
    // cognito pre-token-validation override custom attribute
    event.response = {
        claimsOverrideDetails: {
            claimsToAddOrOverride: {
                "custom:externalid": 121212
            }
        }
    };
    return event;
};
