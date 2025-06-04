import os

def create_directory_structure():
    # Define the base directory
    base_dir = "lib"
    
    # Define the complete directory structure
    structure = {
        "main.dart": None,
        "app.dart": None,
        "firebase_options.dart": None,
        "core": {
            "constants": {
                "api_constants.dart": None,
                "app_constants.dart": None,
                "color_constants.dart": None,
                "string_constants.dart": None
            },
            "config": {
                "app_config.dart": None,
                "dio_config.dart": None,
                "websocket_config.dart": None
            },
            "utils": {
                "date_utils.dart": None,
                "file_utils.dart": None,
                "phone_utils.dart": None,
                "permission_utils.dart": None,
                "validation_utils.dart": None
            },
            "extensions": {
                "context_extensions.dart": None,
                "string_extensions.dart": None,
                "datetime_extensions.dart": None,
                "widget_extensions.dart": None
            },
            "exceptions": {
                "app_exception.dart": None,
                "network_exception.dart": None,
                "auth_exception.dart": None
            }
        },
        "models": {
            "auth": {
                "user_model.dart": None,
                "login_request.dart": None,
                "register_request.dart": None,
                "otp_request.dart": None,
                "auth_response.dart": None
            },
            "chat": {
                "chat_model.dart": None,
                "message_model.dart": None,
                "participant_model.dart": None,
                "chat_settings.dart": None
            },
            "group": {
                "group_model.dart": None,
                "group_member.dart": None,
                "group_settings.dart": None,
                "group_invite.dart": None
            },
            "call": {
                "call_model.dart": None,
                "call_participant.dart": None,
                "call_settings.dart": None,
                "webrtc_models.dart": None
            },
            "file": {
                "file_model.dart": None,
                "media_model.dart": None,
                "upload_response.dart": None
            },
            "common": {
                "api_response.dart": None,
                "pagination_model.dart": None,
                "error_model.dart": None
            }
        },
        "services": {
            "api": {
                "api_service.dart": None,
                "auth_api.dart": None,
                "chat_api.dart": None,
                "group_api.dart": None,
                "call_api.dart": None,
                "file_api.dart": None,
                "message_api.dart": None
            },
            "websocket": {
                "websocket_service.dart": None,
                "chat_socket.dart": None,
                "call_socket.dart": None
            },
            "storage": {
                "secure_storage.dart": None,
                "local_storage.dart": None,
                "cache_service.dart": None
            },
            "notification": {
                "fcm_service.dart": None,
                "local_notification.dart": None,
                "notification_handler.dart": None
            },
            "media": {
                "media_service.dart": None,
                "image_service.dart": None,
                "video_service.dart": None,
                "audio_service.dart": None,
                "file_picker_service.dart": None
            },
            "call": {
                "webrtc_service.dart": None,
                "call_manager.dart": None,
                "signaling_service.dart": None
            },
            "location": {
                "location_service.dart": None,
                "maps_service.dart": None
            }
        },
        "providers": {
            "auth": {
                "auth_provider.dart": None,
                "user_provider.dart": None,
                "auth_state.dart": None
            },
            "chat": {
                "chat_provider.dart": None,
                "message_provider.dart": None,
                "typing_provider.dart": None,
                "chat_list_provider.dart": None
            },
            "group": {
                "group_provider.dart": None,
                "group_member_provider.dart": None,
                "group_settings_provider.dart": None
            },
            "call": {
                "call_provider.dart": None,
                "webrtc_provider.dart": None,
                "call_history_provider.dart": None
            },
            "file": {
                "file_provider.dart": None,
                "media_provider.dart": None,
                "upload_provider.dart": None
            },
            "settings": {
                "settings_provider.dart": None,
                "theme_provider.dart": None,
                "language_provider.dart": None
            },
            "common": {
                "connectivity_provider.dart": None,
                "permission_provider.dart": None,
                "notification_provider.dart": None
            }
        },
        "screens": {
            "auth": {
                "login_screen.dart": None,
                "register_screen.dart": None,
                "otp_verification_screen.dart": None,
                "phone_input_screen.dart": None,
                "profile_setup_screen.dart": None
            },
            "chat": {
                "chat_list_screen.dart": None,
                "chat_screen.dart": None,
                "chat_info_screen.dart": None,
                "new_chat_screen.dart": None,
                "search_chat_screen.dart": None
            },
            "group": {
                "group_list_screen.dart": None,
                "group_chat_screen.dart": None,
                "group_info_screen.dart": None,
                "create_group_screen.dart": None,
                "add_members_screen.dart": None,
                "group_settings_screen.dart": None,
                "group_invite_screen.dart": None
            },
            "call": {
                "call_screen.dart": None,
                "incoming_call_screen.dart": None,
                "outgoing_call_screen.dart": None,
                "call_history_screen.dart": None,
                "video_call_screen.dart": None
            },
            "settings": {
                "settings_screen.dart": None,
                "profile_screen.dart": None,
                "privacy_screen.dart": None,
                "notification_settings_screen.dart": None,
                "chat_settings_screen.dart": None,
                "storage_settings_screen.dart": None,
                "about_screen.dart": None
            },
            "media": {
                "image_viewer_screen.dart": None,
                "video_player_screen.dart": None,
                "document_viewer_screen.dart": None,
                "camera_screen.dart": None,
                "gallery_screen.dart": None
            },
            "status": {
                "status_screen.dart": None,
                "add_status_screen.dart": None,
                "status_viewer_screen.dart": None,
                "status_privacy_screen.dart": None
            },
            "common": {
                "splash_screen.dart": None,
                "onboarding_screen.dart": None,
                "main_navigation_screen.dart": None,
                "search_screen.dart": None,
                "error_screen.dart": None
            }
        },
        "widgets": {
            "common": {
                "custom_app_bar.dart": None,
                "custom_button.dart": None,
                "custom_text_field.dart": None,
                "custom_dialog.dart": None,
                "custom_bottom_sheet.dart": None,
                "loading_widget.dart": None,
                "error_widget.dart": None,
                "empty_state_widget.dart": None,
                "custom_fab.dart": None,
                "custom_badge.dart": None,
                "custom_divider.dart": None
            },
            "auth": {
                "phone_input_widget.dart": None,
                "otp_input_widget.dart": None,
                "country_picker_widget.dart": None,
                "profile_picture_widget.dart": None
            },
            "chat": {
                "chat_tile.dart": None,
                "message_bubble.dart": None,
                "message_input.dart": None,
                "typing_indicator.dart": None,
                "voice_note_player.dart": None,
                "chat_app_bar.dart": None,
                "message_reply_preview.dart": None,
                "emoji_picker_widget.dart": None,
                "attachment_picker.dart": None,
                "read_receipt_widget.dart": None
            },
            "group": {
                "group_tile.dart": None,
                "group_member_tile.dart": None,
                "group_info_widget.dart": None,
                "member_picker_widget.dart": None,
                "group_permissions_widget.dart": None
            },
            "call": {
                "call_tile.dart": None,
                "call_controls.dart": None,
                "call_participant_widget.dart": None,
                "call_overlay.dart": None,
                "call_stats_widget.dart": None
            },
            "media": {
                "image_message_widget.dart": None,
                "video_message_widget.dart": None,
                "audio_message_widget.dart": None,
                "document_message_widget.dart": None,
                "location_message_widget.dart": None,
                "contact_message_widget.dart": None,
                "media_grid_widget.dart": None,
                "media_thumbnail.dart": None
            },
            "settings": {
                "settings_tile.dart": None,
                "settings_section.dart": None,
                "switch_tile.dart": None,
                "slider_tile.dart": None
            },
            "status": {
                "status_tile.dart": None,
                "status_viewer_widget.dart": None,
                "status_progress_widget.dart": None,
                "status_input_widget.dart": None
            }
        },
        "router": {
            "app_router.dart": None,
            "route_names.dart": None,
            "route_transitions.dart": None,
            "router_config.dart": None
        },
        "theme": {
            "app_theme.dart": None,
            "light_theme.dart": None,
            "dark_theme.dart": None,
            "colors.dart": None,
            "text_styles.dart": None,
            "dimensions.dart": None,
            "custom_theme_extensions.dart": None
        }
    }

    def create_structure(base_path, structure):
        # Create the base directory if it doesn't exist
        if not os.path.exists(base_path):
            os.makedirs(base_path)

        # Iterate through the structure
        for name, content in structure.items():
            path = os.path.join(base_path, name)
            
            if content is None:  # It's a file
                # Create empty file
                with open(path, 'w') as f:
                    pass
            else:  # It's a directory
                # Create directory and recurse
                os.makedirs(path, exist_ok=True)
                create_structure(path, content)

    # Create the structure starting from the base directory
    create_structure(base_dir, structure)
    print(f"Directory structure created successfully under '{base_dir}'")

if __name__ == "__main__":
    create_directory_structure()
