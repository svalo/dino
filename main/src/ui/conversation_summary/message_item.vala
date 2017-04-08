using Gee;
using Gdk;
using Gtk;
using Markup;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

[GtkTemplate (ui = "/org/dino-im/conversation_summary/message_item.ui")]
public class MessageItem : Grid, ConversationItem {

    [GtkChild] private Image image;
    [GtkChild] private Label time_label;
    [GtkChild] private Image encryption_image;
    [GtkChild] private Image received_image;

    public StreamInteractor stream_interactor;
    public Conversation conversation { get; set; }
    public Jid from { get; private set; }
    public DateTime initial_time { get; private set; }
    public ArrayList<Message> messages = new ArrayList<Message>(Message.equals_func);

    public MessageItem(StreamInteractor stream_interactor, Conversation conversation, Message message) {
        this.conversation = conversation;
        this.stream_interactor = stream_interactor;
        this.initial_time = message.time;
        this.from = message.from;

        if (message.encryption != Encryption.NONE) {
            encryption_image.visible = true;
            encryption_image.set_from_icon_name("changes-prevent-symbolic", IconSize.SMALL_TOOLBAR);
        }

        time_label.label = get_relative_time(initial_time.to_local());
        Util.image_set_from_scaled_pixbuf(image, (new AvatarGenerator(30, 30, image.scale_factor)).draw_message(stream_interactor, message));
    }

    public void set_title_widget(Widget w) {
        attach(w, 1, 0, 1, 1);
    }

    public void set_main_widget(Widget w) {
        attach(w, 1, 1, 2, 1);
    }

    public void update() {
        time_label.label = get_relative_time(initial_time.to_local());
    }

    public virtual void add_message(Message message) {
        messages.add(message);

        message.notify["marked"].connect_after(() => {
            Idle.add(() => { update_received(); return false; });
        });
        update_received();
    }

    public virtual bool merge(Message message) {
        return false;
    }

    private void update_received() {
        bool all_received = true;
        bool all_read = true;
        foreach (Message message in messages) {
            if (message.marked == Message.Marked.WONTSEND) {
                received_image.visible = true;
                received_image.set_from_icon_name("dialog-warning-symbolic", IconSize.SMALL_TOOLBAR);
                Util.force_error_color(received_image);
                Util.force_error_color(encryption_image);
                Util.force_error_color(time_label);
                return;
            } else if (message.marked != Message.Marked.READ) {
                all_read = false;
                if (message.marked != Message.Marked.RECEIVED) {
                    all_received = false;
                }
            }
        }
        if (all_read) {
            received_image.visible = true;
            received_image.set_from_icon_name("dino-double-tick-symbolic", IconSize.SMALL_TOOLBAR);
        } else if (all_received) {
            received_image.visible = true;
            received_image.set_from_icon_name("dino-tick-symbolic", IconSize.SMALL_TOOLBAR);
        } else if (received_image.visible) {
            received_image.set_from_icon_name("image-loading-symbolic", IconSize.SMALL_TOOLBAR);
        }
    }

    private static string get_relative_time(DateTime datetime) {
        DateTime now = new DateTime.now_local();
        TimeSpan timespan = now.difference(datetime);
        if (timespan > 365 * TimeSpan.DAY) {
            return datetime.format("%d.%m.%Y %H:%M");
        } else if (timespan > 7 * TimeSpan.DAY) {
            return datetime.format("%d.%m %H:%M");
        } else if (timespan > 1 * TimeSpan.DAY) {
            return datetime.format("%a, %H:%M");
        } else if (timespan > 9 * TimeSpan.MINUTE) {
            return datetime.format("%H:%M");
        } else if (timespan > TimeSpan.MINUTE) {
            return (timespan / TimeSpan.MINUTE).to_string() + " min ago";
        } else {
            return _("Just now");
        }
    }
}

}
