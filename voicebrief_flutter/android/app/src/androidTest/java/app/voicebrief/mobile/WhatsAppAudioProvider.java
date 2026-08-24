package app.voicebrief.mobile;

import android.content.ContentProvider;
import android.content.ContentValues;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.OpenableColumns;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

public final class WhatsAppAudioProvider extends ContentProvider {
    private static final String ASSET_NAME = "whatsapp-voice-note.opus";

    @Override
    public boolean onCreate() {
        return true;
    }

    @Override
    public String getType(Uri uri) {
        return "audio/ogg";
    }

    @Override
    public Cursor query(
            Uri uri,
            String[] projection,
            String selection,
            String[] selectionArgs,
            String sortOrder
    ) {
        String[] columns = projection != null
                ? projection
                : new String[]{OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE};
        MatrixCursor cursor = new MatrixCursor(columns);
        Object[] row = new Object[columns.length];
        for (int index = 0; index < columns.length; index++) {
            if (OpenableColumns.DISPLAY_NAME.equals(columns[index])) {
                row[index] = uri.getLastPathSegment() != null
                        ? uri.getLastPathSegment()
                        : ASSET_NAME;
            } else if (OpenableColumns.SIZE.equals(columns[index])) {
                row[index] = assetSize();
            }
        }
        cursor.addRow(row);
        return cursor;
    }

    @Override
    public ParcelFileDescriptor openFile(Uri uri, String mode) throws FileNotFoundException {
        if (!"r".equals(mode)) {
            throw new FileNotFoundException("Read-only test provider");
        }
        if (getContext() == null) {
            throw new FileNotFoundException("Missing provider context");
        }
        try {
            ParcelFileDescriptor[] pipe = ParcelFileDescriptor.createPipe();
            new Thread(() -> writeAsset(pipe[1]), "voicebrief-test-audio").start();
            return pipe[0];
        } catch (IOException error) {
            throw new FileNotFoundException(error.getMessage());
        }
    }

    private long assetSize() {
        if (getContext() == null) return 0;
        try (InputStream input = getContext().getAssets().open(ASSET_NAME)) {
            return input.available();
        } catch (IOException ignored) {
            return 0;
        }
    }

    private void writeAsset(ParcelFileDescriptor outputDescriptor) {
        if (getContext() == null) return;
        try (
                InputStream input = getContext().getAssets().open(ASSET_NAME);
                OutputStream output = new ParcelFileDescriptor.AutoCloseOutputStream(outputDescriptor)
        ) {
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) {
                output.write(buffer, 0, read);
            }
        } catch (IOException ignored) {
            // The target app reports a failed import if the test pipe closes early.
        }
    }

    @Override
    public Uri insert(Uri uri, ContentValues values) {
        return null;
    }

    @Override
    public int delete(Uri uri, String selection, String[] selectionArgs) {
        return 0;
    }

    @Override
    public int update(Uri uri, ContentValues values, String selection, String[] selectionArgs) {
        return 0;
    }
}
