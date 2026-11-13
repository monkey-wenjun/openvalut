package app.openvalut;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;

/**
 * Foreground service that keeps the app process alive while the vault is
 * unlocked.
 *
 * <p>Aggressive ROMs (OnePlus/ColorOS etc.) kill backgrounded tasks after a
 * few seconds. When that happens while the user is on a browser login page,
 * the next autofill request cold-starts the app and forces a second master
 * password entry. Keeping the process alive means the already-unlocked vault
 * stays in memory, and the autofill request is answered by the running app
 * without any unlock screen.
 */
public class KeepAliveService extends Service {
    private static final String TAG = "KeepAliveService";
    private static final String CHANNEL_ID = "openvalut_keepalive";
    private static final int NOTIFICATION_ID = 1;

    public static void start(Context context) {
        try {
            context.startForegroundService(
                new Intent(context, KeepAliveService.class)
            );
        } catch (Exception e) {
            Log.w(TAG, "Unable to start keep-alive service.", e);
        }
    }

    public static void stop(Context context) {
        try {
            context.stopService(new Intent(context, KeepAliveService.class));
        } catch (Exception e) {
            Log.w(TAG, "Unable to stop keep-alive service.", e);
        }
    }

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        startForeground(NOTIFICATION_ID, buildNotification());
        return START_STICKY;
    }

    private Notification buildNotification() {
        Intent openIntent = new Intent(this, MainActivity.class);
        openIntent.setFlags(
            Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP
        );
        PendingIntent contentIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT
        );

        Notification.Builder builder = Build.VERSION.SDK_INT
                >= Build.VERSION_CODES.O
            ? new Notification.Builder(this, CHANNEL_ID)
            : new Notification.Builder(this);
        builder.setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle("OpenValut 已解锁")
            .setContentText("保持后台运行，浏览器自动填充无需再次解锁")
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setShowWhen(false);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(
                Notification.FOREGROUND_SERVICE_IMMEDIATE
            );
        }
        return builder.build();
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "OpenValut 保持解锁",
                NotificationManager.IMPORTANCE_LOW
            );
            channel.setDescription("保持进程运行以便自动填充");
            channel.setShowBadge(false);
            NotificationManager nm = getSystemService(NotificationManager.class);
            nm.createNotificationChannel(channel);
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
