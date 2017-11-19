/*
* Copyright (c) 2009-2013 Yorba Foundation
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public errordomain ConfigurationError {
    PROPERTY_HAS_NO_VALUE,
    /**
      * the underlying configuration engine reported an error; the error is
      * specific to the configuration engine in use (e.g., GSettings)
      * and is usually meaningless to client code */
    ENGINE_ERROR,
}

public enum FuzzyPropertyState {
    ENABLED,
    DISABLED,
    UNKNOWN
}

public enum ConfigurableProperty {
    AUTO_IMPORT_FROM_LIBRARY = 0,
    COMMIT_METADATA_TO_MASTERS,
    DESKTOP_BACKGROUND_FILE,
    DESKTOP_BACKGROUND_MODE,
    DIRECTORY_PATTERN,
    DIRECTORY_PATTERN_CUSTOM,
    EXTERNAL_PHOTO_APP,
    EXTERNAL_RAW_APP,
    HIDE_PHOTOS_ALREADY_IMPORTED,
    IMPORT_DIR,
    KEEP_RELATIVITY,
    LAST_CROP_HEIGHT,
    LAST_CROP_MENU_CHOICE,
    LAST_CROP_WIDTH,
    LAST_USED_SERVICE,
    LAST_USED_DATAIMPORTS_SERVICE,
    MODIFY_ORIGINALS,
    PHOTO_THUMBNAIL_SCALE,
    RAW_DEVELOPER_DEFAULT,
    SHOW_WELCOME_DIALOG,
    USE_24_HOUR_TIME,
    USE_LOWERCASE_FILENAMES,
    VIDEO_INTERPRETER_STATE_COOKIE,


    NUM_PROPERTIES;

    public string to_string () {
        switch (this) {
        case AUTO_IMPORT_FROM_LIBRARY:
            return "AUTO_IMPORT_FROM_LIBRARY";

        case COMMIT_METADATA_TO_MASTERS:
            return "COMMIT_METADATA_TO_MASTERS";

        case DESKTOP_BACKGROUND_FILE:
            return "DESKTOP_BACKGROUND_FILE";

        case DESKTOP_BACKGROUND_MODE:
            return "DESKTOP_BACKGROUND_MODE";

        case DIRECTORY_PATTERN:
            return "DIRECTORY_PATTERN";

        case DIRECTORY_PATTERN_CUSTOM:
            return "DIRECTORY_PATTERN_CUSTOM";

        case EXTERNAL_PHOTO_APP:
            return "EXTERNAL_PHOTO_APP";

        case EXTERNAL_RAW_APP:
            return "EXTERNAL_RAW_APP";

        case HIDE_PHOTOS_ALREADY_IMPORTED:
            return "HIDE_PHOTOS_ALREADY_IMPORTED";

        case IMPORT_DIR:
            return "IMPORT_DIR";

        case KEEP_RELATIVITY:
            return "KEEP_RELATIVITY";

        case LAST_CROP_HEIGHT:
            return "LAST_CROP_HEIGHT";

        case LAST_CROP_MENU_CHOICE:
            return "LAST_CROP_MENU_CHOICE";

        case LAST_CROP_WIDTH:
            return "LAST_CROP_WIDTH";

        case LAST_USED_SERVICE:
            return "LAST_USED_SERVICE";

        case LAST_USED_DATAIMPORTS_SERVICE:
            return "LAST_USED_DATAIMPORTS_SERVICE";

        case MODIFY_ORIGINALS:
            return "MODIFY_ORIGINALS";

        case PHOTO_THUMBNAIL_SCALE:
            return "PHOTO_THUMBNAIL_SCALE";

        case RAW_DEVELOPER_DEFAULT:
            return "RAW_DEVELOPER_DEFAULT";

        case SHOW_WELCOME_DIALOG:
            return "SHOW_WELCOME_DIALOG";

        case USE_24_HOUR_TIME:
            return "USE_24_HOUR_TIME";

        case USE_LOWERCASE_FILENAMES:
            return "USE_LOWERCASE_FILENAMES";

        case VIDEO_INTERPRETER_STATE_COOKIE:
            return "VIDEO_INTERPRETER_STATE_COOKIE";

        default:
            error ("unknown ConfigurableProperty enumeration value");
        }
    }
}

public interface ConfigurationEngine : GLib.Object {
    public signal void property_changed (ConfigurableProperty p);

    public abstract string get_name ();

    public abstract int get_int_property (ConfigurableProperty p) throws ConfigurationError;
    public abstract void set_int_property (ConfigurableProperty p, int val) throws ConfigurationError;

    public abstract string get_string_property (ConfigurableProperty p) throws ConfigurationError;
    public abstract void set_string_property (ConfigurableProperty p, string val) throws ConfigurationError;

    public abstract bool get_bool_property (ConfigurableProperty p) throws ConfigurationError;
    public abstract void set_bool_property (ConfigurableProperty p, bool val) throws ConfigurationError;

    public abstract double get_double_property (ConfigurableProperty p) throws ConfigurationError;
    public abstract void set_double_property (ConfigurableProperty p, double val) throws ConfigurationError;

    public abstract bool get_plugin_bool (string domain, string id, string key, bool def);
    public abstract void set_plugin_bool (string domain, string id, string key, bool val);
    public abstract double get_plugin_double (string domain, string id, string key, double def);
    public abstract void set_plugin_double (string domain, string id, string key, double val);
    public abstract int get_plugin_int (string domain, string id, string key, int def);
    public abstract void set_plugin_int (string domain, string id, string key, int val);
    public abstract string? get_plugin_string (string domain, string id, string key, string? def);
    public abstract void set_plugin_string (string domain, string id, string key, string? val);
    public abstract void unset_plugin_key (string domain, string id, string key);

    public abstract FuzzyPropertyState is_plugin_enabled (string id);
    public abstract void set_plugin_enabled (string id, bool enabled);
}

public abstract class ConfigurationFacade : Object {
    private ConfigurationEngine engine;

    public signal void auto_import_from_library_changed ();
    public signal void commit_metadata_to_masters_changed ();
    public signal void external_app_changed ();
    public signal void import_directory_changed ();

    protected ConfigurationFacade (ConfigurationEngine engine) {
        this.engine = engine;

        engine.property_changed.connect (on_property_changed);
    }

    private void on_property_changed (ConfigurableProperty p) {
        debug ("ConfigurationFacade: engine reports property '%s' changed.", p.to_string ());

        switch (p) {
        case ConfigurableProperty.AUTO_IMPORT_FROM_LIBRARY:
            auto_import_from_library_changed ();
            break;

        case ConfigurableProperty.COMMIT_METADATA_TO_MASTERS:
            commit_metadata_to_masters_changed ();
            break;

        case ConfigurableProperty.EXTERNAL_PHOTO_APP:
        case ConfigurableProperty.EXTERNAL_RAW_APP:
            external_app_changed ();
            break;

        case ConfigurableProperty.IMPORT_DIR:
            import_directory_changed ();
            break;
        }
    }

    protected ConfigurationEngine get_engine () {
        return engine;
    }

    protected void on_configuration_error (ConfigurationError err) {
        if (err is ConfigurationError.PROPERTY_HAS_NO_VALUE) {
            message ("configuration engine '%s' reports PROPERTY_HAS_NO_VALUE error: %s",
                     engine.get_name (), err.message);
        } else if (err is ConfigurationError.ENGINE_ERROR) {
            critical ("configuration engine '%s' reports ENGINE_ERROR: %s",
                      engine.get_name (), err.message);
        } else {
            critical ("configuration engine '%s' reports unknown error: %s",
                      engine.get_name (), err.message);
        }
    }

    //
    // auto import from library
    //
    public virtual bool get_auto_import_from_library () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.AUTO_IMPORT_FROM_LIBRARY);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return false;
        }
    }

    public virtual void set_auto_import_from_library (bool auto_import) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.AUTO_IMPORT_FROM_LIBRARY,
                                             auto_import);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return;
        }
    }

    //
    // commit metadata to masters
    //
    public virtual bool get_commit_metadata_to_masters () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.COMMIT_METADATA_TO_MASTERS);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return false;
        }
    }

    public virtual void set_commit_metadata_to_masters (bool commit_metadata) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.COMMIT_METADATA_TO_MASTERS,
                                             commit_metadata);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return;
        }
    }

    //
    // desktop background
    //
    public virtual string get_desktop_background () {
        try {
            return get_engine ().get_string_property (ConfigurableProperty.DESKTOP_BACKGROUND_FILE);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return "";
        }
    }

    public virtual void set_desktop_background (string filename) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.DESKTOP_BACKGROUND_FILE,
                                               filename);
            get_engine ().set_string_property (ConfigurableProperty.DESKTOP_BACKGROUND_MODE,
                                               "zoom");
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // directory pattern
    //
    public virtual string? get_directory_pattern () {
        try {
            string s = get_engine ().get_string_property (ConfigurableProperty.DIRECTORY_PATTERN);
            return (s == "") ? null : s;
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return "";
        }
    }

    public virtual void set_directory_pattern (string? s) {
        try {
            if (s == null)
                s = "";

            get_engine ().set_string_property (ConfigurableProperty.DIRECTORY_PATTERN, s);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // directory pattern custom
    //
    public virtual string get_directory_pattern_custom () {
        try {
            return get_engine ().get_string_property (ConfigurableProperty.DIRECTORY_PATTERN_CUSTOM);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return "";
        }
    }

    public virtual void set_directory_pattern_custom (string s) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.DIRECTORY_PATTERN_CUSTOM, s);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // external photo app
    //
    public virtual string get_external_photo_app () {
        try {
            return get_engine ().get_string_property (ConfigurableProperty.EXTERNAL_PHOTO_APP);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return "";
        }
    }

    public virtual void set_external_photo_app (string external_photo_app) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.EXTERNAL_PHOTO_APP,
                                               external_photo_app);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return;
        }
    }

    //
    // external raw app
    //
    public virtual string get_external_raw_app () {
        try {
            return get_engine ().get_string_property (ConfigurableProperty.EXTERNAL_RAW_APP);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return "";
        }
    }

    public virtual void set_external_raw_app (string external_raw_app) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.EXTERNAL_RAW_APP,
                                               external_raw_app);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return;
        }
    }

    //
    // Default RAW developer.
    //
    public virtual RawDeveloper get_default_raw_developer () {
        try {
            return RawDeveloper.from_string (get_engine ().get_string_property (
                                                 ConfigurableProperty.RAW_DEVELOPER_DEFAULT));
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return RawDeveloper.CAMERA;
        }
    }

    public virtual void set_default_raw_developer (RawDeveloper d) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.RAW_DEVELOPER_DEFAULT,
                                               d.to_string ());
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return;
        }
    }

    //
    // hide photos already imported
    //
    public virtual bool get_hide_photos_already_imported () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.HIDE_PHOTOS_ALREADY_IMPORTED);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return true;
        }
    }

    public virtual void set_hide_photos_already_imported (bool hide_imported) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.HIDE_PHOTOS_ALREADY_IMPORTED, hide_imported);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // import dir
    //
    public virtual string get_import_dir () {
        try {
            return get_engine ().get_string_property (ConfigurableProperty.IMPORT_DIR);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return "";
        }
    }

    public virtual void set_import_dir (string import_dir) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.IMPORT_DIR, import_dir);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // keep relativity
    //
    public virtual bool get_keep_relativity () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.KEEP_RELATIVITY);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return true;
        }
    }

    public virtual void set_keep_relativity (bool keep_relativity) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.KEEP_RELATIVITY, keep_relativity);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // last crop height
    //
    public virtual int get_last_crop_height () {
        try {
            return get_engine ().get_int_property (ConfigurableProperty.LAST_CROP_HEIGHT);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return 1;
        }
    }

    public virtual void set_last_crop_height (int choice) {
        try {
            get_engine ().set_int_property (ConfigurableProperty.LAST_CROP_HEIGHT, choice);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // last crop menu choice
    //
    public virtual int get_last_crop_menu_choice () {
        try {
            return get_engine ().get_int_property (ConfigurableProperty.LAST_CROP_MENU_CHOICE);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            // in the event we can't get a reasonable value from the configuration engine, we
            // return the empty string since it won't match the name of any existing publishing
            // service -- this will cause the publishing subsystem to select the first service
            // loaded that supports the user's media type
            return 0;
        }
    }

    public virtual void set_last_crop_menu_choice (int choice) {
        try {
            get_engine ().set_int_property (ConfigurableProperty.LAST_CROP_MENU_CHOICE, choice);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // last crop width
    //
    public virtual int get_last_crop_width () {
        try {
            return get_engine ().get_int_property (ConfigurableProperty.LAST_CROP_WIDTH);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return 1;
        }
    }

    public virtual void set_last_crop_width (int choice) {
        try {
            get_engine ().set_int_property (ConfigurableProperty.LAST_CROP_WIDTH, choice);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // last used service
    //
    public virtual string get_last_used_service () {
        try {
            return get_engine ().get_string_property (ConfigurableProperty.LAST_USED_SERVICE);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            // in the event we can't get a reasonable value from the configuration engine, we
            // return the empty string since it won't match the name of any existing publishing
            // service -- this will cause the publishing subsystem to select the first service
            // loaded that supports the user's media type
            return "";
        }
    }

    public virtual void set_last_used_service (string service_name) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.LAST_USED_SERVICE, service_name);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // last used import service
    //
    public virtual string get_last_used_dataimports_service () {
        try {
            return get_engine ().get_string_property (ConfigurableProperty.LAST_USED_DATAIMPORTS_SERVICE);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            // in the event we can't get a reasonable value from the configuration engine, we
            // return the empty string since it won't match the name of any existing import
            // service -- this will cause the import subsystem to select the first service
            // loaded
            return "";
        }
    }

    public virtual void set_last_used_dataimports_service (string service_name) {
        try {
            get_engine ().set_string_property (ConfigurableProperty.LAST_USED_DATAIMPORTS_SERVICE, service_name);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // modify originals
    //
    public virtual bool get_modify_originals () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.MODIFY_ORIGINALS);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            // if we can't get a reasonable value from the configuration engine, don't modify
            // originals
            return false;
        }
    }

    public virtual void set_modify_originals (bool modify_originals) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.MODIFY_ORIGINALS, modify_originals);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // photo thumbnail scale
    //
    public virtual int get_photo_thumbnail_scale () {
        try {
            return get_engine ().get_int_property (ConfigurableProperty.PHOTO_THUMBNAIL_SCALE);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
            return Thumbnail.DEFAULT_SCALE;
        }
    }

    public virtual void set_photo_thumbnail_scale (int scale) {
        try {
            get_engine ().set_int_property (ConfigurableProperty.PHOTO_THUMBNAIL_SCALE, scale);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // show welcome dialog
    //
    public virtual bool get_show_welcome_dialog () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.SHOW_WELCOME_DIALOG);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return true;
        }
    }

    public virtual void set_show_welcome_dialog (bool show) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.SHOW_WELCOME_DIALOG,
                                             show);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // use 24 hour time
    //
    public virtual bool get_use_24_hour_time () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.USE_24_HOUR_TIME);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            // if we can't get a reasonable value from the configuration system, then use the
            // operating system default for the user's country and region.
            return is_string_empty (Time.local (0).format ("%p"));
        }
    }

    public virtual void set_use_24_hour_time (bool use_24_hour_time) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.USE_24_HOUR_TIME, use_24_hour_time);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // use lowercase filenames
    //
    public virtual bool get_use_lowercase_filenames () {
        try {
            return get_engine ().get_bool_property (ConfigurableProperty.USE_LOWERCASE_FILENAMES);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return false;
        }
    }

    public virtual void set_use_lowercase_filenames (bool b) {
        try {
            get_engine ().set_bool_property (ConfigurableProperty.USE_LOWERCASE_FILENAMES, b);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // video interpreter state cookie
    //
    public virtual int get_video_interpreter_state_cookie () {
        try {
            return get_engine ().get_int_property (
                       ConfigurableProperty.VIDEO_INTERPRETER_STATE_COOKIE);
        } catch (ConfigurationError err) {
            on_configuration_error (err);

            return -1;
        }
    }

    public virtual void set_video_interpreter_state_cookie (int state_cookie) {
        try {
            get_engine ().set_int_property (ConfigurableProperty.VIDEO_INTERPRETER_STATE_COOKIE,
                                            state_cookie);
        } catch (ConfigurationError err) {
            on_configuration_error (err);
        }
    }

    //
    // allow plugins to get & set arbitrary properties
    //
    public virtual bool get_plugin_bool (string domain, string id, string key, bool def) {
        return get_engine ().get_plugin_bool (domain, id, key, def);
    }

    public virtual void set_plugin_bool (string domain, string id, string key, bool val) {
        get_engine ().set_plugin_bool (domain, id, key, val);
    }

    public virtual double get_plugin_double (string domain, string id, string key, double def) {
        return get_engine ().get_plugin_double (domain, id, key, def);
    }

    public virtual void set_plugin_double (string domain, string id, string key, double val) {
        get_engine ().set_plugin_double (domain, id, key, val);
    }

    public virtual int get_plugin_int (string domain, string id, string key, int def) {
        return get_engine ().get_plugin_int (domain, id, key, def);
    }

    public virtual void set_plugin_int (string domain, string id, string key, int val) {
        get_engine ().set_plugin_int (domain, id, key, val);
    }

    public virtual string? get_plugin_string (string domain, string id, string key, string? def) {
        string? result = get_engine ().get_plugin_string (domain, id, key, def);
        return (result == "") ? null : result;
    }

    public virtual void set_plugin_string (string domain, string id, string key, string? val) {
        if (val == null)
            val = "";

        get_engine ().set_plugin_string (domain, id, key, val);
    }

    public virtual void unset_plugin_key (string domain, string id, string key) {
        get_engine ().unset_plugin_key (domain, id, key);
    }

    //
    // enable & disable plugins
    //
    public virtual FuzzyPropertyState is_plugin_enabled (string id) {
        return get_engine ().is_plugin_enabled (id);
    }

    public virtual void set_plugin_enabled (string id, bool enabled) {
        get_engine ().set_plugin_enabled (id, enabled);
    }
}
