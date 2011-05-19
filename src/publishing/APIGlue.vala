/* Copyright 2011 Yorba Foundation
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution. 
 */
namespace Publishing.Glue {

public class MediaSourcePublishableWrapper : Spit.Publishing.Publishable, GLib.Object {
    private static int name_ticker = 0;

    private MediaSource wrapped;
    private GLib.File? serialized_file = null;
    
    public MediaSourcePublishableWrapper(MediaSource to_wrap) {
        wrapped = to_wrap;
    }
    
    public void clean_up() {
        if (serialized_file == null)
            return;

        debug("cleaning up temporary publishing file '%s'.", serialized_file.get_path());

        try {
            serialized_file.delete(null);
        } catch (Error err) {
            warning("couldn't delete temporary publishing file '%s'.", serialized_file.get_path());
        }

        serialized_file = null;
    }

    public GLib.File serialize_for_publishing(int content_major_axis,
        bool strip_metadata = false) throws Spit.Publishing.PublishingError {

        if (wrapped is LibraryPhoto) {
            LibraryPhoto photo = (LibraryPhoto) wrapped;

            GLib.File to_file =
                AppDirs.get_temp_dir().get_child("publishing-%d.jpg".printf(name_ticker++));

            debug("writing photo '%s' to temporary file '%s' for publishing.",
                photo.get_source_id(), to_file.get_path());
            try {
                Scaling scaling = (content_major_axis > 0) ?
                    Scaling.for_best_fit(content_major_axis, false) : Scaling.for_original();
                photo.export(to_file, scaling, Jpeg.Quality.HIGH, PhotoFileFormat.JFIF);
            } catch (Error err) {
                throw new Spit.Publishing.PublishingError.LOCAL_FILE_ERROR(
                    "unable to serialize photo '%s' for publishing.", photo.get_name());
            }

            serialized_file = to_file;
        } else if (wrapped is Video) {
            Video video = (Video) wrapped;

            string basename;
            string extension;
            disassemble_filename(video.get_file().get_basename(), out basename, out extension);

            GLib.File to_file =
                GLib.File.new_for_path("publishing-%d.%s".printf(name_ticker++, extension));

            debug("writing video '%s' to temporary file '%s' for publishing.",
                video.get_source_id(), to_file.get_path());
            try {
                video.export(to_file);
            } catch (Error err) {
                throw new Spit.Publishing.PublishingError.LOCAL_FILE_ERROR(
                    "unable to serialize video '%s' for publishing.", video.get_name());
            }

            serialized_file = to_file;
        } else {
            error("MediaSourcePublishableWrapper.serialize_for_publishing( ): unknown media type.");
        }

        return serialized_file;
    }

    public string get_publishing_name() {
        return wrapped.get_name();
    }

    public string? get_publishing_description() {
        return null;
    }

    public string[] get_publishing_keywords() {
        string[] result = new string[0];
        
        Gee.Collection<Tag>? tagset = Tag.global.fetch_sorted_for_source(wrapped);
        if (tagset != null) {
            foreach (Tag tag in tagset) {
                result += tag.get_name();
            }
        }
        
        return (result.length > 0) ? result : null;
    }

    public Spit.Publishing.Publisher.MediaType get_media_type() {
        if (wrapped is LibraryPhoto)
            return Spit.Publishing.Publisher.MediaType.PHOTO;
        else if (wrapped is Video)
            return Spit.Publishing.Publisher.MediaType.VIDEO;
        else
            return Spit.Publishing.Publisher.MediaType.NONE;
    }
    
    public GLib.File? get_serialized_file() {
        return serialized_file;
    }
    
    public GLib.DateTime get_exposure_date_time() {
        return new GLib.DateTime.from_unix_local(wrapped.get_exposure_time());
    }
}

}
